#!/bin/bash
# Rebuild lumec/lasm and the Windows test programs, then the driver, lumec and lasm of both tool trees.
cd "$(dirname "$0")"
bash build_win64.sh > rebuild_win64.log 2>&1 || { echo "build_win64 failed"; tail -20 rebuild_win64.log; exit 1; }
echo "build_win64 ok"
bash build_inst_win64.sh lume_driver lumec lasm $EXTRA > inst_win64.log 2>&1; tail -n 2 inst_win64.log
bash build_inst_linux.sh lume_driver lumec lasm $EXTRA > inst_linux.log 2>&1; tail -n 2 inst_linux.log
