#!/bin/bash
# lume test on every file of a list with the Linux tool tree. Usage: tests_linux.sh [list] [outdir]
cd "$(dirname "$0")/../../.."
L=${1:-build/windows-native/mem/tests_list.txt}; O=${2:-build/windows-native/mem/lt_l}
rm -rf $O; mkdir -p $O
# a fresh, empty home per run: no test may read or write the real ~/.lume, ~/.lume_sovereign_memory or /var/lib vaults
H=$PWD/$O.home; rm -rf $H; mkdir -p $H/win $H/vault
export HOME=$H USERPROFILE=$H LUME_WIN_HOME=$H/win LUME_SYSTEM_VAULT=$H/vault
while read f; do [ -z "$f" ] && continue; n=$(echo "$f" | tr '/' '_' | sed 's/\.src$//;s/\.lume$//'); timeout 1200 build/windows-native/instl/bin/lume test $f < /dev/null > $O/$n.out 2>&1; echo "$n $?"; done < $L > $O/summary.txt
echo "files: $(wc -l < $O/summary.txt), failing: $(grep -vc ' 0$' $O/summary.txt)"
