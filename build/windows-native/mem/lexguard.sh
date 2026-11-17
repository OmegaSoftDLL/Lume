#!/bin/bash
# Edit-time guard (Claude Code PostToolUse hook): every modified or new .src/.lume file of the checkout goes through
# `lume check --lex` (the lexer of the language itself). A raw line break inside a string literal, a bad escape or
# an unclosed """...""" / comment is reported as FILE:LINE:COL and the hook exits 2 so the error reaches the editor
# at once. Files whose modification times did not change since the last clean run are not re-checked.
cd /l/lume 2>/dev/null || cd "$(dirname "$0")/../../.." || exit 0
cat > /dev/null   # the hook payload is not needed: the git state says which files changed
L=build/windows-native/inst/bin/lume.exe
[ -x "$L" ] || exit 0
files=$( { git diff --name-only HEAD; git ls-files --others --exclude-standard; } 2>/dev/null \
  | grep -E '\.(src|lume)$' | sort -u | while read -r f; do [ -f "$f" ] && echo "$f"; done )
[ -n "$files" ] || exit 0
stamp=build/windows-native/mem/.lexguard.stamp
now=$(echo "$files" | while read -r f; do echo "$f $(stat -c %Y "$f")"; done | md5sum | cut -d' ' -f1)
[ -f "$stamp" ] && [ "$(cat "$stamp")" = "$now" ] && exit 0
out=$(echo "$files" | tr '\n' '\0' | xargs -0 "$L" check --lex 2>&1)
if [ $? -ne 0 ]; then
  rm -f "$stamp"
  echo "lume check --lex found lexical errors (fix them before going on):" >&2
  echo "$out" | grep -v 'lexically sound' >&2
  exit 2
fi
echo "$now" > "$stamp"
exit 0
