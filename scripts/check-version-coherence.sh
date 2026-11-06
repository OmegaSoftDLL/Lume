#!/usr/bin/env bash
# Verify that the canonical VERSION file matches all toolchain, manual, formula, CI, and installer version strings.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VER="$(tr -d ' \t\r\n' < VERSION)"
if [[ -z "$VER" ]]; then
    echo "FAIL: VERSION file is empty" >&2
    exit 1
fi

fail=0
check_has() {
    local file="$1"
    local pat="$2"
    if ! grep -Fq "$pat" "$file"; then
        echo "FAIL: $file does not contain '$pat' (expected VERSION=$VER)" >&2
        fail=$((fail + 1))
    fi
}

check_has "compiler/stage1/lcli.src" "lume $VER (edition 2026)"
check_has "compiler/stage1/lmanual.src" "(v$VER / Wave 10)"
check_has "compiler/stage1/lume_driver.src" "\\\"version\\\":\\\"$VER\\\""
check_has "scripts/install.src" "\\\"version\\\":\\\"$VER\\\""
check_has "Formula/lume.rb" "version \"$VER\""
check_has "CHANGELOG.md" "## [$VER]"
check_has ".github/workflows/release.yml" "default: 'v$VER'"
check_has "tests/cli/driver_gate.src" "lume $VER (edition 2026)"
check_has "docs/install.sh" "TAG=\"\${LUME_VERSION:-v$VER}\""

if [[ $fail -ne 0 ]]; then
    echo "FAIL: $fail version coherence check(s) failed for VERSION=$VER" >&2
    exit 1
fi
echo "PASS: version coherence verified for v$VER across 9 surfaces"
