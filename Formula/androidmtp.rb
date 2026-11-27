class Androidmtp < Formula
  desc "Plug-and-play Android MTP → Finder volumes on Apple Silicon"
  homepage "https://github.com/Hashim1999164/androidMTP"
  url "https://github.com/Hashim1999164/androidMTP/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "12eb7f5513492a0ff1d8a2cade50911ba68590edee96315049f83014a868b903"
  license "MIT"
  head "https://github.com/Hashim1999164/androidMTP.git", branch: "main"

  depends_on "go" => :build
  depends_on "pkg-config" => :build
  depends_on "libusb"

  def install
    ENV["CGO_ENABLED"] = "1"
    system "make", "build", "VERSION=#{version}"
    bin.install "bin/androidmtp"
    prefix.install "driver"
  end

  def post_install
    ohai "Installing the Android MTP file system driver"
    system "bash", prefix/"driver/build.sh"
    ohai "Enabling androidmtp plug-and-play"
    system bin/"androidmtp", "enable"
  rescue => e
    opoo "Could not finish setup (#{e}). Run: bash driver/build.sh && androidmtp enable"
  end

  def caveats
    <<~EOS
      Plug-and-play is enabled after install.

        androidmtp status

      Unlock any Android phone → File Transfer / MTP → the phone appears
      in Finder under Locations, next to Macintosh HD.

      Turn on Android MTP under System Settings → General →
      Login Items & Extensions → File System Extensions.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/androidmtp --version")
  end
end
