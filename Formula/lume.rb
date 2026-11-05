class Lume < Formula
  desc "Self-hosted, formally verified systems, AI, and quantum programming language"
  homepage "https://github.com/OmegaSoftDLL/lume"
  version "1.0.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-macos-aarch64.tar.gz"
      sha256 "2e74da87b080b05c48f6df5d557616b946aa92a7141ef419a604d15e320f9a56"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-macos-x86_64.tar.gz"
      sha256 "7e84b76487d25d15136ea4ab460461baf5ae282cc5417cbb28506bb4e0d09425"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-linux-aarch64.tar.gz"
      sha256 "a1b57d16df154b50750ad45ad3884dac887c82c601718c90bf6ff35e09d16eb6"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-linux-x86_64.tar.gz"
      sha256 "8fb29be0b4a2d4cb03f47a4808c26c29c33711560ef5273a8c4896ee5924a2db"
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
