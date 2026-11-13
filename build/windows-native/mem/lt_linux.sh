#!/bin/bash
# lume test on the stage1 memory test files with the Linux tool tree (instl), for comparison with Windows.
cd "$(dirname "$0")/../../.."
ulimit -s unlimited
for n in gc_ok arena_ok perceus_ok; do
  build/windows-native/instl/bin/lume test compiler/stage1/$n.src > build/windows-native/mem/lt_l_$n.out 2> build/windows-native/mem/lt_l_$n.err
  echo "$n exit=$?"
done
