#!/bin/bash
# one batch of build_inst_<sys>.sh with the sandboxed home: inst_part.sh win64|linux <tool>...
H=/mnt/l/lume/build/windows-native/mem/rebuild.home; mkdir -p $H/win $H/vault
export HOME=$H LUME_WIN_HOME=$H/win LUME_SYSTEM_VAULT=$H/vault PATH=/root/.lume/bin:$PATH
sys=$1; shift
cd /mnt/l/lume/build/windows-native && bash build_inst_$sys.sh "$@" 2>&1 | tail -3
