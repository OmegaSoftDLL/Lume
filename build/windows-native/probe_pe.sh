#!/bin/sh
# PE probes for lasm --pe (run under Linux/WSL after build_lasm.sh).
cd "$(dirname "$0")"
./lasm --pe multi_pe.s > multi_pe.exe; echo "multi build exit=$?"
for n in neg_bare_two_dlls neg_undeclared_dll neg_unresolved_symbol neg_malformed; do
  ./lasm --pe $n.s > $n.exe 2> $n.err; rc=$?; echo "$n exit=$rc: $(head -c 160 $n.err)"
done
# ELF output must be byte-identical between the main lasm and the working-tree lasm
../bin/lasm hello_elf_probe.s > elf_old.bin 2>/dev/null; ./lasm hello_elf_probe.s > elf_new.bin 2>/dev/null
cmp elf_old.bin elf_new.bin && echo "ELF identical ($(wc -c < elf_new.bin) bytes)"
