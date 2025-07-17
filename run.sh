#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: qemu_aarch64_cmd"
    exit 1
fi

set -x

[ -v INIT ] || INIT=

mkdir -p out/EFI
cp -f out/Image ./out/EFI/Image
cat > ./out/EFI/startup.nsh << EOF
fs0:
Image nokaslr root=/dev/vda rw init=/init -- $INIT
EOF

"$@" \
-nodefaults \
-display none \
-serial mon:stdio \
-netdev user,id=vnet \
-device virtio-net-pci,netdev=vnet \
-M sbsa-ref \
-cpu max,x-rme=on \
-smp 1 \
-m 2G \
-drive file=out/SBSA_FLASH0.fd,format=raw,if=pflash \
-drive file=out/SBSA_FLASH1.fd,format=raw,if=pflash \
-drive file=fat:rw:out/EFI,format=raw \
-drive format=raw,file=./out/host.ext4,if=virtio \
-virtfs local,path=$(pwd)/,mount_tag=host,security_model=mapped,readonly=off

rm -rf out/EFI
