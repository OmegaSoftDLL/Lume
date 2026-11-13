#!/bin/bash
cd "$(dirname "$0")/../../.."
mkdir -p build/windows-native/mem/lt_l
while read f; do n=$(basename $f .src); timeout 900 build/windows-native/instl/bin/lume test $f < /dev/null > build/windows-native/mem/lt_l/$n.out 2>&1; echo "$n $?"; done < build/windows-native/mem/tests_list.txt > build/windows-native/mem/lt_l/summary.txt
cat build/windows-native/mem/lt_l/summary.txt
