#!/bin/bash
# Full Linux side of the regression: memory battery, test list, os_run_ok with probes, net.src.
cd "$(dirname "$0")"
bash mem_all_linux.sh > regress_mem_l.log 2>&1; tail -n 1 regress_mem_l.log
bash tests_linux.sh > regress_tests_l.log 2>&1; grep -v " 0$" lt_l/summary.txt; echo "tests: $(wc -l < lt_l/summary.txt) files"
bash osrun_linux.sh 2>&1 | tail -n 2
cd ../../.. && build/windows-native/instl/bin/lume test compiler/stage1/net.src < /dev/null 2>&1 | tail -n 2
