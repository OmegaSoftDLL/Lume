#!/bin/bash
# lumec/lasm (Linux, cross to Windows) from the working tree, then a second Windows tree inst2 = inst with the new
# lumec.exe, lasm.exe and lume_driver.exe: a change can be tried while a battery runs on inst. Sandboxed home.
H=/mnt/l/lume/build/windows-native/mem/rebuild.home; mkdir -p $H/win $H/vault
export HOME=$H LUME_WIN_HOME=$H/win LUME_SYSTEM_VAULT=$H/vault PATH=/root/.lume/bin:$PATH
cd /mnt/l/lume; ulimit -s unlimited 2>/dev/null; set -e
lume run build/windows-native/sync_win64_layer.src "$PWD"
./lume amalgamate > /dev/null
./lume build compiler/stage1/lumec.src -o build/windows-native/lumec
./lume build compiler/stage1/lasm.src -o build/windows-native/lasm
W=build/windows-native; rm -rf $W/inst2/bin $W/inst2/bundles; mkdir -p $W/inst2/bin $W/inst2/bundles   # never rm -rf inst2 itself: it holds junctions into the checkout
cp $W/inst/bin/*.exe $W/inst2/bin/
for n in lumec lasm lume_driver; do
  ./lume build compiler/stage1/$n.src -o $W/inst2/bundles/$n > $W/inst2/bundles/$n.log 2>&1 || true
  b=$W/inst2/bundles/$n.bundled.src; [ -s "$b" ] || b=compiler/stage1/$n.src
  $W/lumec --win64 < "$b" > $W/inst2/bundles/$n.s && $W/lasm --pe $W/inst2/bundles/$n.s > $W/inst2/bin/$n.exe
done
cp $W/inst2/bin/lume_driver.exe $W/inst2/bin/lume.exe; cp $W/inst2/bin/lumec.exe $W/inst2/bin/lc.exe
echo "inst2 ready"
