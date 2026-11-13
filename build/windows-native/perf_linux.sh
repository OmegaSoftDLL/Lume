#!/bin/bash
# Linux timings (best of 5) for the Windows/Linux performance comparison.
cd "$(dirname "$0")"
ulimit -s unlimited 2>/dev/null || true
best() { local b=999999; for i in 1 2 3 4 5; do s=$(date +%s%N); eval "$1" > /dev/null 2>&1; e=$(( ($(date +%s%N) - s) / 1000 )); [ $e -lt $b ] && b=$e; done; printf "%9.1f ms  %s\n" "$(echo "$b/1000" | bc -l)" "$1"; }
best "t/cpu.elf"
best "t/gc.elf"
best "t/hello.elf"
best "./lumec < t/hello.src"
best "./lumec < compiler_probe.src"
