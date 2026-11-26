class Androidmtp < Formula
  desc "Plug-and-play Android MTP → Finder volumes on Apple Silicon"
  homepage "https://github.com/Hashim1999164/androidMTP"
  url "https://github.com/Hashim1999164/androidMTP/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "f22a186aa91cd3d9ca0e07fa2253b5e9caab06e8211e5a814f9ec6a0f86c2575"
  license "MIT"
  head "https://github.com/Hashim1999164/androidMTP.git", branch: "main"

  depends_on "go" => :build
  depends_on "pkg-config" => :build
  depends_on "libusb"

  on_macos do
    resource "fuse-t" do
      url "https://github.com/macos-fuse-t/fuse-t/releases/download/1.2.9/fuse-t-macos-installer-1.2.9.pkg"
      sha256 "a1b893740ded8ea034f1acc522ded1144f4a567a1f416daef8c1441cf2662f7f"
    end
  end

  def install
    ENV["CGO_ENABLED"] = "1"

    fuse_root = buildpath/"fuse-t-prefix"
    resource("fuse-t").stage do
      system "pkgutil", "--expand-full", Dir["*.pkg"].first, "expanded"
      payload = "expanded/fuse-t-core.pkg/Payload/Library/Application Support/fuse-t"
      mkdir_p fuse_root/"include"
      mkdir_p fuse_root/"lib"
      cp_r "#{payload}/include/fuse", fuse_root/"include/fuse"
      cp Dir["#{payload}/lib/libfuse-t*"], fuse_root/"lib/"
      cd fuse_root/"lib" do
        ln_sf Dir["libfuse-t-*.dylib"].first, "libfuse-t.dylib"
        ln_sf Dir["libfuse-t-*.a"].first, "libfuse-t.a"
      end
    end

    cflags = "-I#{fuse_root}/include/fuse"
    ldflags = "-L#{fuse_root}/lib -lfuse-t"

    system "make", "build", "VERSION=#{version}", "CGO_CFLAGS=#{cflags}", "CGO_LDFLAGS=#{ldflags}"

    bin.install "bin/androidmtp"
    lib.install Dir["#{fuse_root}/lib/libfuse-t*.dylib"]
    lib.install Dir["#{fuse_root}/lib/libfuse-t*.a"]
    cd lib do
      ln_sf Dir["libfuse-t-*.dylib"].first, "libfuse-t.dylib"
    end

    dirty = `otool -l #{bin}/androidmtp`.lines.grep(/path /).map { |l| l[/path (.*) \(offset/, 1] }.compact
    dirty.each do |p|
      next if p.nil? || p.empty?
      system "install_name_tool", "-delete_rpath", p, bin/"androidmtp"
    end
    system "install_name_tool", "-add_rpath", lib, bin/"androidmtp"
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

        brew install --cask fuse-t
        androidmtp status

      Unlock phone → File Transfer / MTP → the phone appears in Finder
      under Locations, next to Macintosh HD.

      First launch also installs the Android MTP file system driver.
      Turn it on under System Settings → General → Login Items & Extensions
      → File System Extensions.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/androidmtp --version")
  end
end
