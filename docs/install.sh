#!/bin/sh
# Lume Official Zero-C Multi-Platform Installer (v1.1.0 / Edition 2026)
# Usage: curl -fsSL https://omegasoftdll.github.io/lume/install.sh | sh
set -eu

REPO="${LUME_REPO:-OmegaSoftDLL/lume}"
TAG="${LUME_VERSION:-v1.1.0}"
PREFIX="${LUME_PREFIX:-$HOME/.lume}"

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Linux)
    case "$ARCH" in
      x86_64|amd64)   PLAT="linux-x86_64" ;;
      aarch64|arm64)  PLAT="linux-aarch64" ;;
      riscv64)        PLAT="linux-riscv64" ;;
      *) echo "lume-install: unsupported Linux architecture: $ARCH" >&2; exit 1 ;;
    esac
    ;;
  Darwin)
    case "$ARCH" in
      arm64|aarch64)  PLAT="macos-aarch64" ;;
      x86_64|amd64)   PLAT="macos-x86_64" ;;
      *) echo "lume-install: unsupported macOS architecture: $ARCH" >&2; exit 1 ;;
    esac
    ;;
  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    PLAT="windows-x86_64"
    ;;
  *)
    echo "lume-install: unsupported OS: $OS" >&2
    exit 1
    ;;
esac

ASSET="lume-${TAG}-${PLAT}.tar.gz"
BASE_URL="${LUME_RELEASE_BASE:-https://github.com/${REPO}/releases/download/${TAG}}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "lume-install: downloading ${ASSET} from ${BASE_URL}..."
curl -fSL "${BASE_URL}/${ASSET}" -o "${TMP_DIR}/${ASSET}"
curl -fsSL "${BASE_URL}/SHA256SUMS" -o "${TMP_DIR}/SHA256SUMS"

EXPECTED="$(awk -v a="$ASSET" '$2 == a { print $1; exit }' "${TMP_DIR}/SHA256SUMS")"
if [ -z "$EXPECTED" ]; then
  echo "lume-install: missing SHA-256 entry for ${ASSET} in SHA256SUMS" >&2
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  ACTUAL="$(sha256sum "${TMP_DIR}/${ASSET}" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  ACTUAL="$(shasum -a 256 "${TMP_DIR}/${ASSET}" | awk '{print $1}')"
else
  echo "lume-install: neither sha256sum nor shasum found" >&2
  exit 1
fi

if [ "$ACTUAL" != "$EXPECTED" ]; then
  echo "lume-install: SHA-256 mismatch — refusing to install (expected ${EXPECTED}, got ${ACTUAL})" >&2
  exit 1
fi

echo "lume-install: SHA-256 verified (${ACTUAL}). Extracting to ${PREFIX}..."
mkdir -p "$PREFIX"
tar -xzf "${TMP_DIR}/${ASSET}" -C "$PREFIX"

echo "lume-install: installed Lume ${TAG} (${PLAT}) to ${PREFIX}"
echo "lume-install: add '${PREFIX}/bin' to your PATH:"
echo "  export PATH=\"${PREFIX}/bin:\$PATH\""
