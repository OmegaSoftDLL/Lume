#!/bin/bash
# Full coverage, Linux side: every file with fn test_ (111), then every program (205).
cd "$(dirname "$0")"
bash tests_linux.sh build/windows-native/mem/tests_all.txt build/windows-native/mem/ta_l
bash progs_linux.sh build/windows-native/mem/progs_all.txt build/windows-native/mem/pr_l
