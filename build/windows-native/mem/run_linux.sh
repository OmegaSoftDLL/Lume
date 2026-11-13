#!/bin/bash
# Run the memory battery on Linux: every program plain, then every case of cases.txt. Results in mem/res_linux.
cd "$(dirname "$0")"
R=res_linux; rm -rf $R; mkdir -p $R
one() { # id exe env args
  local id=$1 exe=$2 env=$3 args=$4
  [ "$env" = "-" ] && env=""; [ "$args" = "-" ] && args=""
  ( cd $R && env $env timeout 300 ../bin/$exe $args > $id.out 2> $id.err; echo $? > $id.code )
}
for e in bin/*.elf; do n=$(basename $e .elf); one plain_$n $n.elf - -; done
grep -v '^#' cases.txt | while IFS='|' read id t env args; do one $id $t.elf "$env" "$args"; done
for c in $R/*.code; do echo "$(basename $c .code) $(cat $c)"; done > $R/summary.txt
wc -l $R/summary.txt
