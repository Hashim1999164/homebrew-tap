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

  on_macos do
    resource "fuse-t" do
      url "https://github.com/macos-fuse-t/fuse-t/releases/download/1.2.9/fuse-t-macos-installer-1.2.9.pkg"
      sha256 "a1b893740ded8ea034f1acc522ded1144f4a567a1f416daef8c1441cf2662f7f"
    end
  end

  def install
    ENV["CGO_ENABLED"] = "1"

    resource("fuse-t").stage do
      system "pkgutil", "--expand-full", Dir["*.pkg"].first, "expanded"
      payload = "expanded/fuse-t-core.pkg/Payload/Library/Application Support/fuse-t"
      fuse_root = buildpath/"fuse-t-prefix"
      mkdir_p fuse_root/"include"
      mkdir_p fuse_root/"lib"
      mkdir_p fuse_root/"lib/pkgconfig"
      cp_r "#{payload}/include/fuse", fuse_root/"include/fuse"
      cp Dir["#{payload}/lib/libfuse-t*"], fuse_root/"lib"
      cd fuse_root/"lib" do
        ln_sf Dir["libfuse-t-*.dylib"].first, "libfuse-t.dylib"
        ln_sf Dir["libfuse-t-*.a"].first, "libfuse-t.a"
      end
      (fuse_root/"lib/pkgconfig/fuse.pc").write <<~EOS
        prefix=#{fuse_root}
        libdir=${prefix}/lib
        includedir=${prefix}/include/fuse
        Name: fuse-t
        Description: FUSE-T
        Version: 1.2.9
        Libs: -L${libdir} -Wl,-rpath,${libdir} -lfuse-t
        Cflags: -I${includedir}
      EOS
      ENV.prepend_path "PKG_CONFIG_PATH", fuse_root/"lib/pkgconfig"
      ENV["CGO_CFLAGS"] = "-I#{fuse_root}/include/fuse"
      ENV["CGO_LDFLAGS"] = "-L#{fuse_root}/lib -Wl,-rpath,#{fuse_root}/lib -lfuse-t"
    end

    system "make", "build", "VERSION=#{version}"
    bin.install "bin/androidmtp"
  end

  def caveats
    <<~EOS
      Runtime requires FUSE-T (Finder volumes, no kext):

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
