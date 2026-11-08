class Lume < Formula
  desc "Self-hosted, formally verified systems, AI, and quantum programming language"
  homepage "https://github.com/OmegaSoftDLL/lume"
  version "1.1.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-macos-aarch64.tar.gz"
      sha256 "7ff795dfef3ae4e3a7a6e18bb73c452df46469beecc69ce1a275207ea5c067eb"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-macos-x86_64.tar.gz"
      sha256 "5d7955ca27f3525d1230c94f632838f5b9436cf623fda142a297eedd8b6b3198"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-aarch64.tar.gz"
      sha256 "cb7f2a499ae29eff8f7e3d1bbc7f82a84a0b12d1a2118b1258c28a0099bfbedf"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-x86_64.tar.gz"
      sha256 "65e6f1f1c9b3352a818efe2a625874928a6cedc04b2e9592955a9ef706a2c243"
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
