#!/bin/bash
# Build a Windows install tree (build/windows-native/inst/bin/*.exe) of the driver and every tool it dispatches to,
# from the working tree: the Linux driver bundles each source, then lumec --win64 + lasm --pe produce the .exe.
cd "$(dirname "$0")/../.."
ulimit -s unlimited 2>/dev/null || true
W=build/windows-native
mkdir -p $W/inst/bin $W/inst/bundles
TOOLS="lume_driver lumec lasm lmod lcaas lcert lchameleon lcli lconcurrency lcrypto_tls ldoc leconomy levidence levolve lfmt linteractive lkir lmanual lmcdc lmesh lneural_cartridge los lproof_cache lprotect lqualify lregistry lriscv larm64 lsafety_envelope lsentience lsha lsmt lstack lstd ltarget ltest ltv ltv_multiarch ltv_rt lx509 lume_make native_installer amalgamate"
[ $# -gt 0 ] && TOOLS="$*"
ok=0; fail=0
for n in $TOOLS; do
  src=compiler/stage1/$n.src
  [ "$n" = native_installer ] && src=scripts/install.src
  [ -f "$src" ] || src=scripts/$n.src
  [ -f "$src" ] || src=tests/harness/$n.src
  if [ ! -f "$src" ]; then echo "MISSING SOURCE $n"; fail=$((fail+1)); continue; fi
  # the installed Linux driver/lumec may predate the new builtins: only the bundle it writes is needed here
  ./lume build "$src" -o $W/inst/bundles/$n > $W/inst/bundles/$n.build.log 2>&1
  b=$W/inst/bundles/$n.bundled.src
  if [ ! -s "$b" ] && grep -q "^use " "$src"; then echo "BUNDLE FAILED $n"; fail=$((fail+1)); continue; fi
  [ -f "$b" ] || b=$src
  if ! $W/lumec --win64 < "$b" > $W/inst/bundles/$n.win.s 2> $W/inst/bundles/$n.win.err; then echo "WIN64 COMPILE FAILED $n: $(head -c 200 $W/inst/bundles/$n.win.err)"; fail=$((fail+1)); continue; fi
  if ! $W/lasm --pe $W/inst/bundles/$n.win.s > $W/inst/bin/$n.exe 2> $W/inst/bundles/$n.pe.err; then echo "PE ASSEMBLE FAILED $n: $(head -c 200 $W/inst/bundles/$n.pe.err)"; fail=$((fail+1)); continue; fi
  ok=$((ok+1))
done
cp $W/inst/bin/lume_driver.exe $W/inst/bin/lume.exe
cp $W/inst/bin/lumec.exe $W/inst/bin/lc.exe
echo "tools built: $ok, failed: $fail"
