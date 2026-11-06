class Lume < Formula
  desc "Self-hosted, formally verified systems, AI, and quantum programming language"
  homepage "https://github.com/OmegaSoftDLL/lume"
  version "1.1.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-macos-aarch64.tar.gz"
      sha256 "43913c0b137d93df1b6b52dffa71de9242864a57d572c6f81c6731d5a943c0f5"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-macos-x86_64.tar.gz"
      sha256 "0fcd25aa0c031e6fab37f665a4bef36f522dc491bc880b43bffa804d99b2c401"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-aarch64.tar.gz"
      sha256 "0a5573d64626eaf7070df150fdee76b0376cb02a4e083f704c82674ff435e681"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-x86_64.tar.gz"
      sha256 "aad0aa32c417b4e1ad8d47edbd6d0cfe52943873c339ad9cbde59d1955dd96cd"
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
