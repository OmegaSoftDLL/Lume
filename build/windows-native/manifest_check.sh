#!/bin/bash
# Verify MANIFEST.sha256 against the working tree (Linux/WSL); list mismatches.
cd "$(dirname "$0")/../.."
total=$(grep -c . MANIFEST.sha256)
sha256sum -c MANIFEST.sha256 2>/dev/null | grep -v ': OK$' > build/windows-native/manifest_mismatch.txt
echo "manifest entries: $total, not OK: $(wc -l < build/windows-native/manifest_mismatch.txt)"
cat build/windows-native/manifest_mismatch.txt
