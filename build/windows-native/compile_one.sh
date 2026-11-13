#!/bin/bash
cd "$(dirname "$0")"
./lumec --win64 < t/$1.src > t/$1.s && ./lasm --pe t/$1.s > t/$1.exe && echo "built t/$1.exe"
