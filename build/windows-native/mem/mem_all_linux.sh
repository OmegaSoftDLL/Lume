#!/bin/bash
cd "$(dirname "$0")/.."
ulimit -s unlimited
bash mem/compile_all.sh > mem/compile.log 2>&1
grep -v "linux=0 windows=0" mem/compile.log
bash mem/run_linux.sh
