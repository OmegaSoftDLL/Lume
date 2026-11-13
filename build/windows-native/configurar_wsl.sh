#!/bin/bash
# Montagem automatica do Dev Drive L: no WSL (rodar como root, uma vez). Tres camadas:
#  1. /etc/fstab: monta /mnt/l quando o WSL inicia (nofail: nao trava se o L: ainda nao estiver montado no Windows);
#  2. /usr/local/bin/montar-l: monta sob demanda, a qualquer momento;
#  3. /etc/profile.d/lume-l.sh: todo shell de login chama o montar-l.
set -e
mkdir -p /mnt/l
grep -q '^L: /mnt/l ' /etc/fstab 2>/dev/null || echo 'L: /mnt/l drvfs metadata,nofail 0 0' >> /etc/fstab
cat > /usr/local/bin/montar-l <<'SH'
#!/bin/bash
# monta o Dev Drive L: do Windows em /mnt/l, se ainda nao estiver montado
mkdir -p /mnt/l
if mountpoint -q /mnt/l; then exit 0; fi
if [ "$(id -u)" = 0 ]; then mount -t drvfs L: /mnt/l -o metadata 2>/dev/null; else sudo -n mount -t drvfs L: /mnt/l -o metadata 2>/dev/null; fi
mountpoint -q /mnt/l || { echo "montar-l: o L: nao esta disponivel (monte C:\DevDrive\lume.vhdx no Windows)" >&2; exit 1; }
SH
chmod +x /usr/local/bin/montar-l
printf '%s\n' '# Dev Drive do Lume' '/usr/local/bin/montar-l 2>/dev/null || true' > /etc/profile.d/lume-l.sh
echo "fstab: $(grep '^L: ' /etc/fstab)"; /usr/local/bin/montar-l && echo "montado: $(ls /mnt/l | tr '\n' ' ')"
