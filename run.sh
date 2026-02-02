#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: qemu_x86_64_cmd"
    exit 1
fi

set -x

[ -v INIT ] || INIT=/host/io_benchmark.sh

"$@" \
-nodefaults \
-display none \
-serial mon:stdio \
-netdev user,id=vnet \
-device virtio-net-pci,netdev=vnet \
-accel kvm \
-cpu host \
-smp 1 \
-m 8G \
-kernel ./out/bzImage \
-drive format=raw,file=./out/host.ext4,if=virtio \
--blockdev null-co,node-name=drive1,size=$((20 * 1024 * 1024 * 1024)) \
--object iothread,id=iothread0 \
--device virtio-blk-pci,drive=drive1,iothread=iothread0 \
-append "nokaslr console=ttyS0 root=/dev/vdb rw init=/init -- $INIT" \
-virtfs local,path=$(pwd)/,mount_tag=host,security_model=mapped,readonly=off
