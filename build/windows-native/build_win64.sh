#!/bin/bash
# Rebuild lumec + lasm from the working tree (Linux/WSL) and compile the Windows test programs.
cd "$(dirname "$0")/../.."
ulimit -s unlimited 2>/dev/null || true
set -e
lume run build/windows-native/sync_win64_layer.src "$PWD"
./lume amalgamate > /dev/null
./lume build compiler/stage1/lumec.src -o build/windows-native/lumec
./lume build compiler/stage1/lasm.src -o build/windows-native/lasm
for f in build/windows-native/t/*.src; do
  b=${f%.src}
  build/windows-native/lumec --win64 < "$f" > "$b.s"
  build/windows-native/lasm --pe "$b.s" > "$b.exe"
  echo "built $b.exe ($(wc -c < "$b.exe") bytes)"
done
