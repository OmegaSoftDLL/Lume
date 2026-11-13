#!/bin/bash
cd "$(dirname "$0")/../../.."
build/windows-native/instl/bin/lume test compiler/stage1/hostio.src; echo "exit=$?"
