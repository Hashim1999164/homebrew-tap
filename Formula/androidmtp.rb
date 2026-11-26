class Androidmtp < Formula
  desc "Plug-and-play Android MTP → Finder volumes on Apple Silicon"
  homepage "https://github.com/Hashim1999164/androidMTP"
  url "https://github.com/Hashim1999164/androidMTP/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "81f93d162ac0886ea64943ca5c1196091d2d0ed1b0918551d008f3e88c266f33"
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
  end

  def post_install
    ohai "Enabling androidmtp plug-and-play"
    system bin/"androidmtp", "enable"
  rescue => e
    opoo "Could not auto-enable agent (#{e}). Run: androidmtp enable"
  end

  def caveats
    <<~EOS
      Plug-and-play is enabled after install.

      Also install FUSE-T helpers if you have not:

        brew install --cask fuse-t

      Then unlock phone → File Transfer / MTP → Finder opens automatically.

        androidmtp status
        androidmtp disable
        androidmtp enable
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/androidmtp --version")
  end
end
