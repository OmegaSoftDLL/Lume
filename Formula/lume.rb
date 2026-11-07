class Lume < Formula
  desc "Self-hosted, formally verified systems, AI, and quantum programming language"
  homepage "https://github.com/OmegaSoftDLL/lume"
  version "1.1.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-macos-aarch64.tar.gz"
      sha256 "dac9b2ca3c4600ddf8038ce58d3be6738bf43224ec25d0799a2d2cc24cf52690"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-macos-x86_64.tar.gz"
      sha256 "4ed9a6735a44cd27d5265bc6ab03c89e73ebc43157681e6b3daa16cf10f79850"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-aarch64.tar.gz"
      sha256 "c51837604c80146be173051858ad7a718c1c2d2ffba9c8f70e058ffa88df14e6"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-x86_64.tar.gz"
      sha256 "2eb32f51438b1b71acc8ee5377b760a5296ecd6aaabbf53e929e7e151805b759"
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
