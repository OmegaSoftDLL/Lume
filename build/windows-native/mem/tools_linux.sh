#!/bin/bash
# Rebuild tools of the project's build/bin with the current driver and lumec: tools_linux.sh <tool>...
# (a tool's source: compiler/stage1, then scripts; native_installer is scripts/install.src). Sandboxed home.
H=/mnt/l/lume/build/windows-native/mem/rebuild.home; mkdir -p $H/win $H/vault
export HOME=$H LUME_WIN_HOME=$H/win LUME_SYSTEM_VAULT=$H/vault
cd /mnt/l/lume; ulimit -s unlimited 2>/dev/null
ok=0; bad=""
for t in "$@"; do
  s=compiler/stage1/$t.src; [ -f $s ] || s=scripts/$t.src; [ "$t" = native_installer ] && s=scripts/install.src
  if ./lume build $s -o build/bin/$t.stage > /tmp/tool_$t.log 2>&1 && [ -s build/bin/$t.stage ]; then
    [ -f build/bin/$t ] && cp -p build/bin/$t build/bin/$t.prev; mv -f build/bin/$t.stage build/bin/$t; ok=$((ok+1))
  else bad="$bad $t"; tail -3 /tmp/tool_$t.log; rm -f build/bin/$t.stage; fi
done
sync; echo 3 > /proc/sys/vm/drop_caches
echo "rebuilt $ok, failed:${bad:- none}"
