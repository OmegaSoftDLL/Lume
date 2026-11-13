#!/bin/bash
# Rebuild everything, give the Linux tree the install layout, run the full Linux coverage.
cd "$(dirname "$0")"
bash rebuild_all.sh
bash link_trees_linux.sh
bash mem/full_linux.sh
