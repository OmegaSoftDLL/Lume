#!/bin/bash
cd "$(dirname "$0")"
bash rebuild_all.sh
bash mem/full_linux.sh
