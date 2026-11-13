#!/bin/bash
cd "$(dirname "$0")"
bash build_win64.sh > rebuild_win64.log 2>&1 || { tail -20 rebuild_win64.log; exit 1; }
./lumec < t/forkt.src > t/forkt.l.s && ./lasm t/forkt.l.s > t/forkt.elf && chmod +x t/forkt.elf && timeout 20 ./t/forkt.elf
