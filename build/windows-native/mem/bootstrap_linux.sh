#!/bin/bash
# The project's own Linux build (build/bin) from the working tree, with a sandboxed home.
# build/bin can predate builtins the sources now use (os_getenv in hostio, buf_*): first lumec and lasm are rebuilt
# with the old compiler (their sources use no new builtin), then `lume bootstrap` rebuilds everything with them and
# checks stage 2 == stage 3. The previous binaries are kept as build/bin/*.prev.
H=/mnt/l/lume/build/windows-native/mem/rebuild.home; mkdir -p $H/win $H/vault
export HOME=$H LUME_WIN_HOME=$H/win LUME_SYSTEM_VAULT=$H/vault
sync; echo 3 > /proc/sys/vm/drop_caches
cd /mnt/l/lume; ulimit -s unlimited 2>/dev/null; set -e
L=build/windows-native/mem/bootstrap_linux.log; : > $L
./lume amalgamate >> $L 2>&1
for t in lumec lasm; do
  ./lume build compiler/stage1/$t.src -o build/bin/$t.stage >> $L 2>&1
  cp -p build/bin/$t build/bin/$t.prev; cp build/bin/$t.stage build/bin/$t; rm -f build/bin/$t.stage
done
echo "lumec and lasm rebuilt with the previous compiler"
set +e; start=$(date +%s); ./lume bootstrap >> $L 2>&1; rc=$?
echo "bootstrap exit=$rc in $(( $(date +%s) - start )) s"; tail -12 $L
ls -la --time-style=+%H:%M build/bin/lumec build/bin/lasm build/bin/lume_driver build/bin/lcli | awk '{print $6, $7}'
