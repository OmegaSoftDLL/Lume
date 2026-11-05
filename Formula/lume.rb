class Lume < Formula
  desc "Self-hosted, formally verified systems, AI, and quantum programming language"
  homepage "https://github.com/OmegaSoftDLL/lume"
  version "1.0.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-macos-aarch64.tar.gz"
      sha256 "98c0c1bbaafb22ff406e7b485748f5cc2556512f0372a20a3edfe478b8096c1f"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-macos-x86_64.tar.gz"
      sha256 "f029008bd0b49e5245eb57ee659c7287b4db49fe414e86b3ca792df77dde7340"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-linux-aarch64.tar.gz"
      sha256 "d9f172f35396019b3e3670d3473bc5760f1cb487dbc2500f87484180b3005388"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-linux-x86_64.tar.gz"
      sha256 "1307a0f1f1ce939caf971ea1fa1f30fb048873a90fb075af8d705000de3b06e3"
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
