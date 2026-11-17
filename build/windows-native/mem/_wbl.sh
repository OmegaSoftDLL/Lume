cd /mnt/l/lume/build/windows-native/mem
for b in "$@"; do if [ "$b" = cpw ]; then bash _cpw.sh; else bash _wb.sh /mnt/l/lume/build/windows-native/mem/wb_$b.lst 2>&1 | grep -E "tools built|FAIL" | sed "s/^/wb_$b: /"; fi; done
