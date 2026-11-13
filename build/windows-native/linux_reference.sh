#!/bin/bash
# Linux reference run of the same test programs (native ELF), for the Windows/Linux differential.
cd "$(dirname "$0")/t"
for f in *.src; do
  b=${f%.src}
  ../lumec < "$f" > "$b.linux.s" && ../lasm "$b.linux.s" > "$b.elf" && chmod +x "$b.elf" || { echo "$b: build failed"; continue; }
  rm -rf lume_win_fs_probe
  ./"$b.elf" a b > "$b.linux.out" 2>&1; echo "exit=$?" >> "$b.linux.out"
  rm -rf lume_win_fs_probe
done
grep -H "" fs.linux.out | head -20
