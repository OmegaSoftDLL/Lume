cd "$(dirname "$0")"
./lumec < t/rss.src > t/rss.linux.s && ./lasm t/rss.linux.s > t/rss.elf && chmod +x t/rss.elf && ./t/rss.elf
