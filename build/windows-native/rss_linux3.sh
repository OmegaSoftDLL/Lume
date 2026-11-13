#!/bin/bash
cd "$(dirname "$0")"
p=rss3; ./lumec --win64 < t/$p.src > t/$p.s && ./lasm --pe t/$p.s > t/$p.exe; ./lumec < t/$p.src > t/$p.l.s && ./lasm t/$p.l.s > t/$p.elf && chmod +x t/$p.elf
echo "linux rss3: $(./t/rss3.elf)"; echo "linux rss1 GC off: $(LUME_GC=off ./t/rss1.elf)"
