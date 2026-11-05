class Lume < Formula
  desc "Self-hosted, formally verified systems, AI, and quantum programming language"
  homepage "https://github.com/OmegaSoftDLL/lume"
  version "1.0.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-macos-aarch64.tar.gz"
      sha256 "2109ccaa06ee1ca758960929ea378d869e52b4b086072ced1c101f2c80eaf44c"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-macos-x86_64.tar.gz"
      sha256 "d98052d47d87195b4cf33acf5b91073dd5aeff7b2c9e6a36715c1726d2021b89"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-linux-aarch64.tar.gz"
      sha256 "a719b97d79f3017a590a90db229f7bfe55a4b73f0ba35078697788e7e04a0387"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-linux-x86_64.tar.gz"
      sha256 "47c831d7dbc1ca1dcfef775b2441bdf3be57c58e0c6d1d6f3ab91a4ae6006cd0"
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
