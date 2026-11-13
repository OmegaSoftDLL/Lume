#!/bin/bash
# Build a Linux install tree (instl/bin) from the same sources and compiler, for the Windows/Linux parity runs.
# from the working tree: the Linux driver bundles each source, then lumec --win64 + lasm --pe produce the .exe.
cd "$(dirname "$0")/../.."
ulimit -s unlimited 2>/dev/null || true
W=build/windows-native
mkdir -p $W/instl/bin $W/instl/bundles
TOOLS="lume_driver lumec lasm lmod lcaas lcert lchameleon lcli lconcurrency lcrypto_tls ldoc leconomy levidence levolve lfmt linteractive lkir lmanual lmcdc lmesh lneural_cartridge los lproof_cache lprotect lqualify lregistry lriscv larm64 lsafety_envelope lsentience lsha lsmt lstack lstd ltarget ltest ltv ltv_multiarch ltv_rt lx509 lume_make native_installer amalgamate"
[ $# -gt 0 ] && TOOLS="$*"
ok=0; fail=0
for n in $TOOLS; do
  src=compiler/stage1/$n.src
  [ -f "$src" ] || src=scripts/$n.src
  [ -f "$src" ] || src=tests/harness/$n.src
  if [ ! -f "$src" ]; then echo "MISSING SOURCE $n"; fail=$((fail+1)); continue; fi
  # the installed Linux driver/lumec may predate the new builtins: only the bundle it writes is needed here
  ./lume build "$src" -o $W/instl/bundles/$n > $W/instl/bundles/$n.build.log 2>&1
  b=$W/instl/bundles/$n.bundled.src
  if [ ! -s "$b" ] && grep -q "^use " "$src"; then echo "BUNDLE FAILED $n"; fail=$((fail+1)); continue; fi
  [ -f "$b" ] || b=$src
  if ! $W/lumec < "$b" > $W/instl/bundles/$n.win.s 2> $W/instl/bundles/$n.win.err; then echo "WIN64 COMPILE FAILED $n: $(head -c 200 $W/instl/bundles/$n.win.err)"; fail=$((fail+1)); continue; fi
  if ! $W/lasm $W/instl/bundles/$n.win.s > $W/instl/bin/$n 2> $W/instl/bundles/$n.pe.err; then echo "PE ASSEMBLE FAILED $n: $(head -c 200 $W/instl/bundles/$n.pe.err)"; fail=$((fail+1)); continue; fi
  chmod +x $W/instl/bin/$n; ok=$((ok+1))
done
cp $W/instl/bin/lume_driver $W/instl/bin/lume
cp $W/instl/bin/lumec $W/instl/bin/lc
echo "tools built: $ok, failed: $fail"
