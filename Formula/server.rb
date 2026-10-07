class Server < Formula
  desc "Self-hosted media server for Live TV, movies, and TV shows"
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
    # Archive layout is a top-level <platform>/ dir containing the server
    # binary (named `kernel`), the transcoder binary (`kernel-transcoder`,
    # installed by the separate `remotenode` formula), and binaries/ (bundled
    # jellyfin-ffmpeg) -- same combined zip the .deb/.rpm packages are built
    # from. This formula only needs the server binary + ffmpeg.
    platform_dir = Dir.glob("*").select { |f| File.directory?(f) }.first
    prefix.install "#{platform_dir}/kernel" => "kernel-server"
    prefix.install "#{platform_dir}/binaries"

    bin.install_symlink prefix/"kernel-server"
  end

  service do
    run [opt_bin/"kernel-server"]
    environment_variables KERNEL_PORT: "9014",
                           # kernel-server resolves ffmpeg relative to its working
                           # directory by default (./binaries, ./bin, ./ffmpeg);
                           # since the service's working_dir is var/kernel-server,
                           # not the Cellar path holding the bundled binaries,
                           # point it at the installed copy explicitly.
                           KERNEL_FFMPEG: opt_prefix/"binaries/ffmpeg",
                           KERNEL_FFPROBE: opt_prefix/"binaries/ffprobe"
    working_dir var/"kernel-server"
    log_path var/"log/kernel-server.log"
    error_log_path var/"log/kernel-server.log"
    keep_alive true
  end

  def post_install
    (var/"kernel-server").mkpath
    (var/"log").mkpath
  end

  test do
    # kernel-server has no --version/one-shot flag (it's a long-running
    # daemon; the only CLI flag is -v for verbose logging), so the smoke
    # test just confirms the binary is in place and executable.
    assert_predicate bin/"kernel-server", :executable?
  end
end
