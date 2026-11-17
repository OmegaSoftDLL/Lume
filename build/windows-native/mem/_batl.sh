cd /mnt/l/lume/build/windows-native/mem
for x in "$@"; do k=${x%_*}; n=${x#*_}; echo "$k $n: $(bash _bat.sh $k $n)"; done
