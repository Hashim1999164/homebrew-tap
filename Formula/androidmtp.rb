class Androidmtp < Formula
  desc "Mount Android MTP devices as Finder volumes on Apple Silicon"
  homepage "https://github.com/Hashim1999164/androidMTP"
  url "https://github.com/Hashim1999164/androidMTP/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "29c23ed46023a14b1ef8a5b06335a1cb43a0e5ecf49bb51b08f47f86cf6f89bc"
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

    # Point the binary at Cellar lib instead of the ephemeral build path.
    dirty = `otool -l #{bin}/androidmtp`.lines.grep(/path /).map { |l| l[/path (.*) \(offset/, 1] }.compact
    dirty.each do |p|
      next if p.nil? || p.empty?
      system "install_name_tool", "-delete_rpath", p, bin/"androidmtp"
    end
    system "install_name_tool", "-add_rpath", lib, bin/"androidmtp"
  end

  def caveats
    <<~EOS
      Runtime also needs the FUSE-T helpers (go-nfsv4):

        brew install --cask fuse-t

      Then:

        androidmtp doctor
        androidmtp mount
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/androidmtp --version")
  end
end
