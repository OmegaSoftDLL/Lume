#!/bin/bash
# Rebuild lumec/lasm + Windows test programs, then the Windows and Linux tool trees, in sequence.
cd "$(dirname "$0")"
bash build_win64.sh > rebuild_win64.log 2>&1 || { echo "build_win64 failed"; tail -20 rebuild_win64.log; exit 1; }
echo "build_win64 ok"
bash build_inst_win64.sh > inst_win64.log 2>&1; tail -n 3 inst_win64.log
bash build_inst_linux.sh > inst_linux.log 2>&1; tail -n 3 inst_linux.log
