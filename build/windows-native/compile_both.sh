#!/bin/bash
# Compile one test program for Windows (.exe) and Linux (.elf), then run the Linux one 5 times.
cd "$(dirname "$0")"
./lumec --win64 < t/$1.src > t/$1.s && ./lasm --pe t/$1.s > t/$1.exe
./lumec < t/$1.src > t/$1.linux.s && ./lasm t/$1.linux.s > t/$1.elf && chmod +x t/$1.elf
for i in 1 2 3 4 5; do ./t/$1.elf | head -2 | tr '\n' ' '; echo; done
