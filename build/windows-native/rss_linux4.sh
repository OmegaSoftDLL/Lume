#!/bin/bash
cd "$(dirname "$0")"
for p in rss4 rss5; do ./lumec --win64 < t/$p.src > t/$p.s && ./lasm --pe t/$p.s > t/$p.exe; ./lumec < t/$p.src > t/$p.l.s && ./lasm t/$p.l.s > t/$p.elf && chmod +x t/$p.elf; echo "linux $p: $(./t/$p.elf)"; done
