#!/bin/bash
# lume test on every file of a list with the Linux tool tree. Usage: tests_linux.sh [list] [outdir]
cd "$(dirname "$0")/../../.."
L=${1:-build/windows-native/mem/tests_list.txt}; O=${2:-build/windows-native/mem/lt_l}
rm -rf $O; mkdir -p $O
while read f; do [ -z "$f" ] && continue; n=$(echo "$f" | tr '/' '_' | sed 's/\.src$//;s/\.lume$//'); timeout 1200 build/windows-native/instl/bin/lume test $f < /dev/null > $O/$n.out 2>&1; echo "$n $?"; done < $L > $O/summary.txt
echo "files: $(wc -l < $O/summary.txt), failing: $(grep -vc ' 0$' $O/summary.txt)"
