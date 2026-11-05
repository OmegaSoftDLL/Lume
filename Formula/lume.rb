class Lume < Formula
  desc "Self-hosted, formally verified systems, AI, and quantum programming language"
  homepage "https://github.com/OmegaSoftDLL/lume"
  version "1.0.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-macos-aarch64.tar.gz"
      sha256 "f1bcc77c60f628f747867c6ee170ba6de79edc60601550a34b9cb51c52c8bb07"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-macos-x86_64.tar.gz"
      sha256 "e44e832d9e87e4326e6f1705f85035542b249b11d167667e3f362af64dcbdebe"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-linux-aarch64.tar.gz"
      sha256 "cef3671b60dd674f7601b3206dfb986a321f1780a33257bfc32d39ff53fdba1e"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.0.0/lume-v1.0.0-linux-x86_64.tar.gz"
      sha256 "03b6c910b78024a0776b519a1cc4aa2062b796a90c50dff561dd75df922c161f"
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
