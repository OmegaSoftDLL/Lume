#!/bin/bash
# Build lumec.exe and lasm.exe (Windows x64) with the working-tree toolchain, plus Linux reference outputs.
cd "$(dirname "$0")/../.."
ulimit -s unlimited 2>/dev/null || true
set -e
W=build/windows-native
mkdir -p $W/tools
for tool in lumec lasm; do
  $W/lumec --win64 < compiler/stage1/$tool.src > $W/tools/$tool.s
  $W/lasm --pe $W/tools/$tool.s > $W/tools/$tool.exe
  echo "built $W/tools/$tool.exe ($(wc -c < $W/tools/$tool.exe) bytes)"
done
# Linux reference: the same inputs through the Linux lumec / lasm
for f in $W/t/*.src; do b=$(basename ${f%.src}); $W/lumec < $f > $W/tools/$b.ref.s; $W/lasm $W/tools/$b.ref.s > $W/tools/$b.ref.elf; $W/lasm --pe $W/tools/$b.ref.s > $W/tools/$b.ref.exe; done
$W/lumec < compiler/stage1/lasm.src > $W/tools/lasm_src.ref.s
echo "reference outputs written"
