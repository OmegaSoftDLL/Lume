#!/bin/bash
cd "$(dirname "$0")/../../.."
ulimit -s unlimited
s=$(date +%s%N); LUME_GC=on build/windows-native/instl/bin/lumec < compiler/stage1/lumec.src > build/windows-native/mem/gg_plain_l.s; echo "plain exit=$? ms=$(( ($(date +%s%N) - s) / 1000000 ))"
s=$(date +%s%N); LUME_GC_STRESS=100000 build/windows-native/instl/bin/lumec < compiler/stage1/lumec.src > build/windows-native/mem/gg_stress_l.s; echo "stress exit=$? ms=$(( ($(date +%s%N) - s) / 1000000 ))"
