#!/bin/bash
# Convert the Win64 layer assembly into runtime_core.lume functions with the Lume converter (Linux/WSL).
cd "$(dirname "$0")"
lume run asm2lume.src rt_win64_imports < win64_imports.s > win64_imports.lume.txt || exit 1
lume run asm2lume.src rt_win64_layer < win64_body.s > win64_layer.lume.txt || exit 1
wc -c win64_imports.lume.txt win64_layer.lume.txt
head -c 300 win64_layer.lume.txt; echo
