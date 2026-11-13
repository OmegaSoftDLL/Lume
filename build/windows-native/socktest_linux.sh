#!/bin/bash
cd "$(dirname "$0")"
./lumec --win64 < t/sock.src > t/sock.s && ./lasm --pe t/sock.s > t/sock.exe && echo "pe ok"
./lumec < t/sock.src > t/sock.l.s && ./lasm t/sock.l.s > t/sock.elf && chmod +x t/sock.elf && ./t/sock.elf
