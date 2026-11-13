#!/bin/bash
cd "$(dirname "$0")"
bash build_inst_win64.sh "$@" > inst_win64_some.log 2>&1; tail -n 3 inst_win64_some.log
bash build_inst_linux.sh "$@" > inst_linux_some.log 2>&1; tail -n 3 inst_linux_some.log
