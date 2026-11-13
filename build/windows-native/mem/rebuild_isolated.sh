#!/bin/bash
# rebuild_all.sh + link_trees_linux.sh with a sandboxed home: the release `lume` used by the build keeps caches and
# memory vaults under the home, and nothing of the build may touch the real ~/.lume_sovereign_memory or /var/lib vaults.
H=/mnt/l/lume/build/windows-native/mem/rebuild.home; rm -rf $H; mkdir -p $H/win $H/vault
export HOME=$H LUME_WIN_HOME=$H/win LUME_SYSTEM_VAULT=$H/vault PATH=/root/.lume/bin:$PATH
cd /mnt/l/lume/build/windows-native
bash rebuild_all.sh && bash link_trees_linux.sh; echo "rebuild exit=$?"
