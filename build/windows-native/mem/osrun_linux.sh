#!/bin/bash
# os_run_ok.src with the probes run.sh builds (Linux tree).
cd "$(dirname "$0")/../../.."
P=$PWD/build/windows-native/mem/probes_l; mkdir -p $P; B=build/windows-native/instl/bin
for p in os_run_probe os_run_slow_probe os_run_input_probe; do
  $B/lumec < compiler/stage1/$p.src > $P/$p.s && $B/lasm $P/$p.s > $P/$p && chmod +x $P/$p
  printf '%s' "$P/$p" > ${p}_path
done
$B/lume test compiler/stage1/os_run_ok.src < /dev/null; echo "exit=$?"
rm -f os_run_probe_path os_run_slow_probe_path os_run_input_probe_path os_run_capture_stdout os_run_capture_stderr os_run_timeout_stdout os_run_timeout_stderr os_run_input_data os_run_input_stdout os_run_input_stderr os_run_input_missing_stdout os_run_input_missing_stderr
