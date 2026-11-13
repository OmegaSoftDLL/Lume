#!/bin/bash
# Every program of a list (Linux tree): stdout, stderr and exit status per program. Usage: progs_linux.sh [list] [outdir]
# Most programs are `lume run`; progs_modes.txt names the others and how they are exercised:
#   kernel       -> `lume build <f> -o <name>.kernel` (a bare-metal image does not run on the host)
#   server       -> `lume run`, still serving after 5 s = 0 (then stopped), an earlier exit = its status
#   gate         -> built, then run with "@root <root>" and "@bin <tool dir>" on stdin, as CI runs gates
#   via <gate>   -> a helper of that gate: the status of the gate run
# progs_verdict.src turns the recorded results into pass/fail (expected refusals included).
cd "$(dirname "$0")/../../.."
R=$PWD; L=${1:-build/windows-native/mem/progs_all.txt}; O=${2:-build/windows-native/mem/pr_l}
M=build/windows-native/mem/progs_modes.txt
rm -rf $O; mkdir -p $O
# a fresh, empty home per run: no test may read or write the real ~/.lume, ~/.lume_sovereign_memory or /var/lib vaults
H=$PWD/$O.home; rm -rf $H; mkdir -p $H/win $H/vault
export HOME=$H USERPROFILE=$H LUME_WIN_HOME=$H/win LUME_SYSTEM_VAULT=$H/vault
LB=${LUME_BIN:-$R/build/windows-native/instl/bin}; case $LB in /*) ;; *) LB=$R/$LB;; esac
BIN=${GATE_BIN:-$( [ -x $LB/lumec ] && echo $LB || echo $LB/build/bin )}
gate_run() {  # gate source, name -> status
  timeout 1800 $LB/lume build $1 -o $O/$2.gate < /dev/null > $O/$2.gate.build 2>&1 || return 3
  printf '@root %s\n@bin %s\n' "$R" "$BIN" | timeout 3600 $O/$2.gate > $O/$2.out 2> $O/$2.err
}
while read f; do [ -z "$f" ] && continue; n=$(echo "$f" | tr '/' '_' | sed 's/\.src$//')
  mode=$(awk -v f="$f" '$1==f{print $2}' $M); arg=$(awk -v f="$f" '$1==f{print $3}' $M)
  case "$mode" in
    kernel) timeout 300 $LB/lume build $f -o $O/$n.kernel < /dev/null > $O/$n.out 2> $O/$n.err; st=$?; rm -f $O/$n.kernel ;;
    server) setsid $LB/lume run $f < /dev/null > $O/$n.out 2> $O/$n.err & pid=$!; sleep 5
            if kill -0 $pid 2>/dev/null; then kill -- -$pid 2>/dev/null; wait $pid 2>/dev/null; st=0; else wait $pid; st=$?; fi ;;
    gate) gate_run $f $n; st=$? ;;
    via) gate_run $arg $n; st=$? ;;
    *) timeout 300 $LB/lume run $f < /dev/null > $O/$n.out 2> $O/$n.err; st=$? ;;
  esac
  echo "$n $st"
done < $L > $O/summary.txt
echo "programs: $(wc -l < $O/summary.txt)"
