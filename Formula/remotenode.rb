class Remotenode < Formula
  desc "Remote transcoder node for Kernel Media Server"
  homepage "https://kernelmedia.tv"
  version "0.8.20"
  license "BSL-1.1"

  on_arm do
    url "https://api.kernelmedia.tv/downloads/public/free/darwin-arm64"
    sha256 "b49ae7e20638b69d0ffe854bf74fdf9008b21ce38d3564bfc6dd0e3aa75a0d93"
  end

  on_intel do
    url "https://api.kernelmedia.tv/downloads/public/free/darwin-amd64"
    sha256 "3a7f64b6a2f0ab8a2a6d1390235adccc6265b47524ba9998e76b6eb5624bf864"
  end

  def install
    # Same combined archive the `server` formula uses (and the .deb/.rpm
    # packages are built from) -- this formula just takes the transcoder
    # binary and the bundled ffmpeg instead of the server binary.
    platform_dir = Dir.glob("*").select { |f| File.directory?(f) }.first
    prefix.install "#{platform_dir}/kernel-transcoder"
    prefix.install "#{platform_dir}/binaries"

    bin.install_symlink prefix/"kernel-transcoder"

    # config.yml defaults ffmpeg.path to "./ffmpeg/ffmpeg", which doesn't
    # match where the release archive actually puts it (binaries/ffmpeg) --
    # same bundled-ffmpeg path kernel-server uses. Write an explicit config
    # instead of relying on the shipped default. Port 9015 (not the node's
    # own default of 9014) so it doesn't collide with a kernel-server
    # instance running on the same Mac.
    (etc/"kernel-remotenode").mkpath
    config = etc/"kernel-remotenode/config.yml"
    config.write <<~YAML
      server:
        host: "0.0.0.0"
        port: 9015
      ffmpeg:
        path: "#{opt_prefix}/binaries/ffmpeg"
      workers:
        max_concurrent: 4
    YAML
  end

  service do
    run [opt_bin/"kernel-transcoder", "-config", etc/"kernel-remotenode/config.yml"]
    working_dir var/"kernel-remotenode"
    log_path var/"log/kernel-remotenode.log"
    error_log_path var/"log/kernel-remotenode.log"
    keep_alive true
  end

  def post_install
    (var/"kernel-remotenode").mkpath
    (var/"log").mkpath
  end

  def caveats
    <<~EOS
      Config: #{etc}/kernel-remotenode/config.yml (port 9015 by default --
      change it if you'd rather it match kernel-server's 9014).

      Pair this node from the Kernel admin UI: Settings > Remote Transcoders.
      It announces itself over UDP multicast automatically; if discovery
      doesn't reach the server (different subnet/VLAN), add it manually by
      ip:port instead.
    EOS
  end

  test do
    assert_predicate bin/"kernel-transcoder", :executable?
  end
end
