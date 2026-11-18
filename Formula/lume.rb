class Lume < Formula
  desc "Self-hosted, formally verified systems, AI, and quantum programming language"
  homepage "https://github.com/OmegaSoftDLL/lume"
  version "1.2.0"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.2.0/lume-v1.2.0-macos-aarch64.tar.gz"
      sha256 "686abd5c599eb68907de8d72fe533c1de012c8fef87aa9c046257a88138a6647"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.2.0/lume-v1.2.0-macos-x86_64.tar.gz"
      sha256 "6967d57df998636ee7d4b210d1292f0ab4dfee16155dc63ac582bd358c6d3cae"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.2.0/lume-v1.2.0-linux-aarch64.tar.gz"
      sha256 "350fa487bc526b4ef537391d825aee29b12d4efda4dfe7649fdb69d9a0cfc8ad"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.2.0/lume-v1.2.0-linux-x86_64.tar.gz"
      sha256 "7de7b3146273ea1545b23769bfcffba4705799461bd0179bee33f30a5ee0f676"
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
