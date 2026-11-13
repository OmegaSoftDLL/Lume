#!/bin/bash
# Every gate of gates_all.txt with the Linux tree: built with `lume build`, then run with "@root <root>" and
# "@bin <tool dir>" on stdin, as CI does. Usage: gates_linux.sh [list] [outdir]   (defaults: gates_all.txt, ga_l)
cd "$(dirname "$0")/../../.."
R=$PWD; L=${1:-build/windows-native/mem/gates_all.txt}; O=$R/build/windows-native/mem/${2:-ga_l}
rm -rf $O; mkdir -p $O/bin
# a fresh, empty home: no gate may read or write the real ~/.lume, ~/.lume_sovereign_memory or /var/lib vaults
H=$O.home; rm -rf $H; mkdir -p $H/win $H/vault
export HOME=$H USERPROFILE=$H LUME_WIN_HOME=$H/win LUME_SYSTEM_VAULT=$H/vault
B=$R/build/windows-native/instl/bin
ulimit -s unlimited 2>/dev/null || ulimit -s 524288 2>/dev/null || true
while read f; do
  [ -z "$f" ] && continue
  n=$(echo "$f" | tr '/' '_' | sed 's/\.src$//')
  if ! timeout 1800 $B/lume build $f -o $O/bin/$n < /dev/null > $O/$n.build 2>&1; then echo "$n BUILD-FAIL"; continue; fi
  printf '@root %s\n@bin %s\n' "$R" "$B" > $O/$n.in
  timeout 3600 $O/bin/$n < $O/$n.in > $O/$n.out 2> $O/$n.err; echo "$n $?"
done < $L > $O/summary.txt
echo "gates: $(wc -l < $O/summary.txt), not 0: $(grep -vc ' 0$' $O/summary.txt)"
