#!/bin/bash
cd "$(dirname "$0")"
ulimit -s unlimited 2>/dev/null || true
/usr/bin/time -f "linux lumec hello: %e s, maxrss %M KB" ./lumec < t/hello.src > /dev/null
strace -c -f ./lumec < t/hello.src > /dev/null 2> tools/strace_hello.txt; head -15 tools/strace_hello.txt
