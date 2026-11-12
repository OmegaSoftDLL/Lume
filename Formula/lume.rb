class Lume < Formula
  desc "Self-hosted, formally verified systems, AI, and quantum programming language"
  homepage "https://github.com/OmegaSoftDLL/lume"
  version "1.1.0"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-macos-aarch64.tar.gz"
      sha256 "d5c37d5a884b703e79bc16dd49f530fd745773c3b5bceec2b1763912e231ca27"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-macos-x86_64.tar.gz"
      sha256 "d1d1c00bf4f584bbff42fca20a8334db6031533c5a79b0d2bb0b19e6f1f710ab"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-aarch64.tar.gz"
      sha256 "0b05a5b7a1d93a381853560ca76129dbca0b8c872f08dc857215852f0a611003"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-x86_64.tar.gz"
      sha256 "60db6a61e36730d0935bd1bac5c2ffe1449bbc4845b115e0dcad9de0377a60d9"
    end
  end

  def install
    libexec.install Dir["*"]
    bin.install_symlink libexec/"bin/lume"
  end

  test do
    assert_match "lume", shell_output("#{bin}/lume --version")
  end
end
