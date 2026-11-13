#!/bin/bash
# Compile every tests/memory/*.src (+ the stage1 memory programs) for Linux (.elf) and Windows (.exe) with the
# freshly built lumec/lasm; compile status and diagnostics go to <name>.cstat / <name>.cerr for both targets.
cd "$(dirname "$0")/.."
# modules (use ...) are bundled by the driver first, as `lume build` does
W=$PWD; O=$W/mem/bin; mkdir -p $O
for f in ../../tests/memory/*.src ../../compiler/stage1/arena_mem.src ../../compiler/stage1/compiler_perceus_ok.src; do
  n=$(basename $f .src)
  if grep -q "^use " $f; then b=$(../../lume bundle $f | tail -n 1); [ -s "$b" ] && f=$b; fi
  ./lumec < $f > $O/$n.l.s 2> $O/$n.l.cerr; lc=$?
  [ $lc = 0 ] && { ./lasm $O/$n.l.s > $O/$n.elf 2>> $O/$n.l.cerr; lc=$?; chmod +x $O/$n.elf; }
  ./lumec --win64 < $f > $O/$n.w.s 2> $O/$n.w.cerr; wc=$?
  [ $wc = 0 ] && { ./lasm --pe $O/$n.w.s > $O/$n.exe 2>> $O/$n.w.cerr; wc=$?; }
  echo "$n linux=$lc windows=$wc"
done
