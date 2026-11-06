class Lume < Formula
  desc "Self-hosted, formally verified systems, AI, and quantum programming language"
  homepage "https://github.com/OmegaSoftDLL/lume"
  version "1.0.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-macos-aarch64.tar.gz"
      sha256 "db34ab2178919b7bee5e01822e1af3f84a67b666c34b732aa404b9b00831c3cb"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-macos-x86_64.tar.gz"
      sha256 "833b12b2347557195f408e63f5c71ad79fd7e6b24eb01b0ccd51953f5d15264f"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-linux-aarch64.tar.gz"
      sha256 "aa6aea08d2f7df97dfc83a1c5e5006c04b037a02fe9b52fecb4eae112cefb97f"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-linux-x86_64.tar.gz"
      sha256 "a03411c81ba672c30ec294e6060358a1be79ef125a65c0ffa66171c9216b2579"
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
