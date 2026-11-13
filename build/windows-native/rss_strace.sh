cd "$(dirname "$0")"
strace -f -v -e trace=wait4 ./t/rss.elf 2>&1 | grep wait4 | grep -v "= 0$" | cut -c1-500 | head -4
