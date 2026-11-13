#!/bin/bash
# Build and run the native assembly gate from the working tree (Linux/WSL).
cd "$(dirname "$0")/../.."
ulimit -s unlimited 2>/dev/null || true
./lume build tests/harness/lasm_gate.src -o build/bin/lasm_gate || { echo "gate build failed"; exit 1; }
printf '@root %s\n' "$PWD" | build/bin/lasm_gate
echo "gate exit=$?"
