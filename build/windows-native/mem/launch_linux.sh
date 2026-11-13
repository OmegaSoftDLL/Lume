#!/bin/bash
cd "$(dirname "$0")/.."
./lumec < t/parity_runner.src > t/parity_runner.l.s && ./lasm t/parity_runner.l.s > t/parity_runner.elf && chmod +x t/parity_runner.elf
for p in hello atomic_compactor_ok; do
  exe=t/hello.elf; [ $p = hello ] && { ./lumec < t/hello.src > t/hello.l.s; ./lasm t/hello.l.s > t/hello.elf; chmod +x t/hello.elf; } || exe=mem/bin/$p.elf
  ./t/parity_runner.elf $exe mem/launch_list.txt mem/launch_l_$p > /dev/null
  echo "$p linux ms: $(awk '{print $4}' mem/launch_l_$p/summary.txt | tr '\n' ' ')"
done
