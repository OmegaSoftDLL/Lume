#!/bin/bash
cd "$(dirname "$0")"
for p in idle rssn fork1 forkt sock argv entropy hello fs gc proc child sleeper traps_stack bigframe; do ./lumec --win64 < t/$p.src > t/$p.s && ./lasm --pe t/$p.s > t/$p.exe || echo "FAIL $p"; done; echo built
