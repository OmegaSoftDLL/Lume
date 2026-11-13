#!/bin/bash
# The install layout has <root>/compiler/stage1 (and stdlib): give the Linux test tree the same view of the checkout.
cd "$(dirname "$0")"
mkdir -p instl/compiler && ln -sfn ../../../../compiler/stage1 instl/compiler/stage1 && ln -sfn ../../../stdlib instl/stdlib && ls instl/compiler/stage1/hostio.src instl/stdlib | head -3
