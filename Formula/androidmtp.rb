class Androidmtp < Formula
  desc "Mount Android MTP devices as Finder volumes on Apple Silicon"
  homepage "https://github.com/Hashim1999164/androidMTP"
  url "https://github.com/Hashim1999164/androidMTP/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "632809cd90b921820f05b8e81f23ea06bbca2e46f19804d7d2ff223ffbbc0878"
  license "MIT"
  head "https://github.com/Hashim1999164/androidMTP.git", branch: "main"

  depends_on "go" => :build
  depends_on "pkg-config" => :build
  depends_on "libusb"

  def install
    fuse_lib = [
      "/usr/local/lib/libfuse-t.dylib",
      "#{Dir.home}/.fuse-t/usr/local/lib/libfuse-t.dylib",
    ].find { |p| File.exist?(p) }
    odie "Install FUSE-T first: brew install --cask fuse-t" unless fuse_lib

    ENV["CGO_ENABLED"] = "1"
    fuse_pc = [
      "/usr/local/lib/pkgconfig",
      "#{Dir.home}/.fuse-t/usr/local/lib/pkgconfig",
    ].find { |p| File.exist?("#{p}/fuse.pc") || File.exist?("#{p}/fuse-t.pc") }
    ENV.prepend_path "PKG_CONFIG_PATH", fuse_pc if fuse_pc

    system "make", "build", "VERSION=#{version}"
    bin.install "bin/androidmtp"
  end

  def caveats
    <<~EOS
      FUSE-T is required (kext-less Finder volumes):

        brew install --cask fuse-t

      Then:

        androidmtp doctor
        androidmtp mount

      Optional auto-mount at login:

        androidmtp install-agent
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/androidmtp --version")
  end
end
