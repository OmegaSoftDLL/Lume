#!/bin/sh
# Build the working-tree lasm with the native toolchain (Linux/WSL) and assemble the PE probe.
set -e
cd "$(dirname "$0")/../.."
./lume build compiler/stage1/lasm.src -o build/windows-native/lasm
build/windows-native/lasm --pe build/windows-native/hello_pe.s > build/windows-native/hello_pe.exe
ls -l build/windows-native/hello_pe.exe
