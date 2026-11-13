#!/bin/bash
cd "$(dirname "$0")"
for p in envchild envparent; do ./lumec --win64 < t/$p.src > t/$p.s && ./lasm --pe t/$p.s > t/$p.exe; ./lumec < t/$p.src > t/$p.l.s && ./lasm t/$p.l.s > t/$p.elf && chmod +x t/$p.elf; done
cp t/envchild.elf t/envchild.lin; mv t/envchild.elf t/envchild.elf.keep
sed 's#t/envchild#t/envchild.lin#' t/envparent.src > /tmp/ep.src; ./lumec < /tmp/ep.src > /tmp/ep.s && ./lasm /tmp/ep.s > /tmp/ep.elf && chmod +x /tmp/ep.elf && /tmp/ep.elf
