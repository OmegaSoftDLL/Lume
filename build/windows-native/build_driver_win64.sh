#!/bin/bash
# Build lume_driver.exe from the bundled driver source with the working-tree lumec --win64 + lasm --pe (Linux/WSL).
cd "$(dirname "$0")/../.."
ulimit -s unlimited 2>/dev/null || true
set -e
W=build/windows-native
./lume build compiler/stage1/lume_driver.src -o $W/tools/lume_driver.linux > /dev/null
ls -la $W/tools/lume_driver.linux.bundled.src | awk '{print "bundled", $5, "bytes"}'
$W/lumec --win64 < $W/tools/lume_driver.linux.bundled.src > $W/tools/lume_driver.s
$W/lasm --pe $W/tools/lume_driver.s > $W/tools/lume_driver.exe
echo "built $W/tools/lume_driver.exe ($(wc -c < $W/tools/lume_driver.exe) bytes)"
