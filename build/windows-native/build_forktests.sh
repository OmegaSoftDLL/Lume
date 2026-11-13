#!/bin/bash
cd "$(dirname "$0")"
for p in fork1 forkt sock; do ./lumec --win64 < t/$p.src > t/$p.s && ./lasm --pe t/$p.s > t/$p.exe && echo "built $p"; done
