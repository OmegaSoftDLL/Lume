# one part of the Linux battery: _bat.sh tests|progs NN
cd /mnt/l/lume/build/windows-native/mem
if [ "$1" = tests ]; then LUME_BIN=/mnt/l/lume bash tests_linux.sh build/windows-native/mem/tests_part_$2 build/windows-native/mem/tl_$2 | tail -1
else LUME_BIN=/mnt/l/lume bash progs_linux.sh build/windows-native/mem/progs_part_$2 build/windows-native/mem/pl_$2 | tail -1; fi
