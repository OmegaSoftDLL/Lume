#!/bin/bash
# The four test files that need what bootstrap/lume0/tests/run.sh sets up, on the Linux tree: run from
# bootstrap/lume0 (as run.sh does), with the probes built and their *_path files written. Usage: precond_linux.sh [outdir]
cd "$(dirname "$0")/../../.."
R=$PWD; O=$R/build/windows-native/mem/${1:-pc_l}; rm -rf $O; mkdir -p $O
# a fresh, empty home: no test may read or write the real ~/.lume, ~/.lume_sovereign_memory or /var/lib vaults
H=$O.home; rm -rf $H; mkdir -p $H/win $H/vault
export HOME=$H USERPROFILE=$H LUME_WIN_HOME=$H/win LUME_SYSTEM_VAULT=$H/vault
B=$R/build/windows-native/instl/bin; P=$R/build/windows-native/mem/probes_l; mkdir -p $P
cd $R/bootstrap/lume0
for p in os_run_probe os_run_slow_probe os_run_input_probe process_probe; do
  [ -x $P/$p ] || { $B/lumec < $R/compiler/stage1/$p.src > $P/$p.s && $B/lasm $P/$p.s > $P/$p && chmod +x $P/$p; }
  printf '%s' "$P/$p" > ${p}_path
done
printf '%s' "$P/os_run_slow_probe" > std_process_slow_probe_path
for t in fs_path_exists_ok fs_read_byte_ok os_run_ok process_ok; do
  timeout 1200 $B/lume test ../../compiler/stage1/$t.src < /dev/null > $O/compiler_stage1_$t.out 2>&1; echo "compiler_stage1_$t $?"
done > $O/summary.txt
rm -f os_run_probe_path os_run_slow_probe_path os_run_input_probe_path process_probe_path std_process_slow_probe_path \
  os_run_capture_stdout os_run_capture_stderr os_run_timeout_stdout os_run_timeout_stderr os_run_input_data \
  os_run_input_stdout os_run_input_stderr os_run_input_missing_stdout os_run_input_missing_stderr \
  std_process_stdin_probe std_process_stdout_probe std_process_stderr_probe fs_read_byte_probe
cat $O/summary.txt
