#!/bin/bash
cd "$(dirname "$0")/bin"
for i in 1 2 3; do s=$(date +%s%N); LUME_HEAP_CAP=32m ./gc_cap_ok.elf > /dev/null; e=$(date +%s%N); echo "gc_cap_ok ms $(( (e - s) / 1000000 ))"; done
for i in 1 2 3; do s=$(date +%s%N); ./atomic_compactor_ok.elf > /dev/null; e=$(date +%s%N); echo "compactor ms $(( (e - s) / 1000000 ))"; done
