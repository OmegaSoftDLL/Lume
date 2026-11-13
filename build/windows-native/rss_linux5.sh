#!/bin/bash
cd "$(dirname "$0")"
p=rssn; ./lumec --win64 < t/$p.src > t/$p.s && ./lasm --pe t/$p.s > t/$p.exe; ./lumec < t/$p.src > t/$p.l.s && ./lasm t/$p.l.s > t/$p.elf && chmod +x t/$p.elf
for n in 0 1 1000 3000 10000 30000 100000 300000 1000000; do ./t/rssn.elf $n; done
