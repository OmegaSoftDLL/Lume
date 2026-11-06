class Lume < Formula
  desc "Self-hosted, formally verified systems, AI, and quantum programming language"
  homepage "https://github.com/OmegaSoftDLL/lume"
  version "1.1.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-macos-aarch64.tar.gz"
      sha256 "705da68c5394789c8d967eb2de5baa1b0c9f1a1ce69ce2cec9794c42e30aae37"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-macos-x86_64.tar.gz"
      sha256 "a529bee745c5fab84a016c59a9a20602f9c7ea6031e76e69b67b7e293da1e6fe"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-aarch64.tar.gz"
      sha256 "9c08c71cc4c7cbf30c7a3e5a59ded354bd918dba1438d12dc39efd420355e5f3"
    else
      url "https://github.com/OmegaSoftDLL/lume/releases/download/v1.1.0/lume-v1.1.0-linux-x86_64.tar.gz"
      sha256 "defd2f9caa743f874e3ab3f45dc8ac1524b1ddd5f61e8af19cf505fa129167ee"
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
