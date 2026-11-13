#!/bin/bash
# `lume run` on every program of a list (Linux tree): stdout, stderr and exit status per program.
cd "$(dirname "$0")/../../.."
L=${1:-build/windows-native/mem/progs_all.txt}; O=${2:-build/windows-native/mem/pr_l}
rm -rf $O; mkdir -p $O
# a fresh, empty home per run: no test may read or write the real ~/.lume, ~/.lume_sovereign_memory or /var/lib vaults
H=$PWD/$O.home; rm -rf $H; mkdir -p $H/win $H/vault
export HOME=$H USERPROFILE=$H LUME_WIN_HOME=$H/win LUME_SYSTEM_VAULT=$H/vault
while read f; do [ -z "$f" ] && continue; n=$(echo "$f" | tr '/' '_' | sed 's/\.src$//'); timeout 300 build/windows-native/instl/bin/lume run $f < /dev/null > $O/$n.out 2> $O/$n.err; echo "$n $?"; done < $L > $O/summary.txt
echo "programs: $(wc -l < $O/summary.txt)"
