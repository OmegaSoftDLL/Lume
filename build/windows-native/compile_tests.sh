#!/bin/bash
# Compile the test programs for Windows (.exe) and Linux (.elf) with the already-built working-tree tools.
cd "$(dirname "$0")"
ulimit -s unlimited 2>/dev/null || true
for f in t/*.src; do
  b=${f%.src}
  ./lumec --win64 < "$f" > "$b.s" && ./lasm --pe "$b.s" > "$b.exe"
  ./lumec < "$f" > "$b.linux.s" && ./lasm "$b.linux.s" > "$b.elf" && chmod +x "$b.elf"
done
cp t/child.elf t/child; cp t/sleeper.elf t/sleeper
./lumec < compiler_probe.src > tools/compiler_probe.ref.s
echo compiled
