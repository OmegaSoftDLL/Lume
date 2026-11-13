#!/bin/bash
cd "$(dirname "$0")"
./lumec --win64 < t/gcbench.src > t/gcbench.s && ./lasm --pe t/gcbench.s > t/gcbench.exe
./lumec < t/gcbench.src > t/gcbench.l.s && ./lasm t/gcbench.l.s > t/gcbench.elf && chmod +x t/gcbench.elf
for i in 1 2 3 4 5; do LUME_HEAP_CAP=64m ./t/gcbench.elf | head -2 | tr '\n' ' '; echo; done
