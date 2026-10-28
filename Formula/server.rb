class Server < Formula
  desc "Self-hosted media server for Live TV, movies, and TV shows"
  homepage "https://kernelmedia.tv"
  version "0.9.1"
  license "BSL-1.1"

  on_arm do
    url "https://api.kernelmedia.tv/downloads/public/free/darwin-arm64"
    sha256 "e4abb1db5d9e617b8a803a97fbc86151b2b5dc27ecc815d2e691296faf1dd443"
  end

  on_intel do
    url "https://api.kernelmedia.tv/downloads/public/free/darwin-amd64"
    sha256 "8ea174ee67fccc9d633778fde723e4806101500a12f4d30434f3ba05d707670b"
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
                           KERNEL_FFPROBE: opt_prefix/"binaries/ffprobe",
                           # Any non-empty value disables the in-app self-updater
                           # (same check apt/yum packages use via their own
                           # KERNEL_MANAGED=apt/yum). Without this, Settings >
                           # Updates would try to swap the binary in place inside
                           # the Cellar, which `brew upgrade` doesn't know about
                           # and would leave the install in a broken state.
                           KERNEL_MANAGED: "brew"
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
