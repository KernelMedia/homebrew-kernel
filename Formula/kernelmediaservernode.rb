class Kernelmediaservernode < Formula
  desc "Remote transcoder node for Kernel Media Server"
  homepage "https://kernelmedia.tv"
  version "0.9.4"
  license "BSL-1.1"

  on_arm do
    url "https://api.kernelmedia.tv/downloads/public/free/darwin-arm64"
    sha256 "f74427d998caccd433bc5fb14455fe3e9db9c086fe99f150e9b899eb24f147d1"
  end

  on_intel do
    url "https://api.kernelmedia.tv/downloads/public/free/darwin-amd64"
    sha256 "16649db8f5ee42bd978c5eba7a77de2da3c2dc325a9b91f3c4de114a94f40329"
  end

  def install
    # Same combined archive the `kernelmediaserver` formula uses (and the .deb/.rpm
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
    # Any non-empty value disables the transcoder's own self-updater, same
    # check kernelmediaservernode's apt/yum packages rely on.
    environment_variables KERNEL_MANAGED: "brew"
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
