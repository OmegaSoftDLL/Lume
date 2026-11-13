#!/bin/bash
# Seed conformance + ASan/UBSan suites required by AGENTS.md before each commit (Linux/WSL).
cd "$(dirname "$0")/../.."
make -C bootstrap/lume0 test > build/windows-native/seed_test.log 2>&1; t=$?
make -C bootstrap/lume0 asan > build/windows-native/seed_asan.log 2>&1; a=$?
echo "test exit=$t: $(grep -E '[0-9]+ passed' build/windows-native/seed_test.log | tail -1)"
echo "asan exit=$a: $(grep -E '[0-9]+ passed' build/windows-native/seed_asan.log | tail -1)"
