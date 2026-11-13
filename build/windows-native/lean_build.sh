#!/bin/bash
cd "$(dirname "$0")"
bash build_win64.sh > rebuild_win64.log 2>&1 || { tail -20 rebuild_win64.log; exit 1; }
for p in idle rssn fork1 forkt sock argv entropy; do ./lumec --win64 < t/$p.src > t/$p.s && ./lasm --pe t/$p.s > t/$p.exe; done; echo built
