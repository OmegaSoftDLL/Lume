cd /mnt/l/lume/build/windows-native/mem
for b in "$@"; do bash _tb.sh /mnt/l/lume/build/windows-native/mem/tb_$b.lst 2>&1 | grep -v ": ok" | grep -v "rebuilt [0-9]*, failed: none"; echo "tb_$b done"; done
