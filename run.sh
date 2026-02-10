#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: qemu_riscv64_cmd"
    exit 1
fi

set -x

[ -v INIT ] || INIT=

"$@" \
-nodefaults \
-display none \
-serial mon:stdio \
-netdev user,id=vnet \
-device virtio-net-pci,netdev=vnet \
-M virt \
-cpu max \
-smp 1 \
-m 8G \
-bios ./out/opensbi.bin \
-kernel ./out/Image \
-drive format=raw,file=./out/host.ext4,if=virtio \
-append "nokaslr root=/dev/vda rw init=/init -- $INIT" \
-virtfs local,path=$(pwd)/,mount_tag=host,security_model=mapped,readonly=off
