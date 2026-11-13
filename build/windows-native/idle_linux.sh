#!/bin/bash
cd "$(dirname "$0")"
./lumec --win64 < t/idle.src > t/idle.s && ./lasm --pe t/idle.s > t/idle.exe
./lumec < t/idle.src > t/idle.l.s && ./lasm t/idle.l.s > t/idle.elf && chmod +x t/idle.elf
./t/idle.elf > /dev/null & pid=$!; sleep 1; grep -E "VmRSS|RssAnon|RssFile|VmHWM" /proc/$pid/status | tr '\n' ' '; echo; wait $pid
