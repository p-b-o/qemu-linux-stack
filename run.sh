#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: qemu_aarch64_cmd"
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
-M virt,secure=on,virtualization=on,gic-version=3,iommu=smmuv3,acpi=off \
-cpu max,x-rme=on \
-smp 1 \
-m 2G \
-bios ./out/flash.bin \
-kernel ./out/Image \
-drive format=raw,file=./out/host.ext4,if=virtio \
-append "nokaslr root=/dev/vda rw init=/init -- $INIT" \
-virtfs local,path=$(pwd)/,mount_tag=host,security_model=mapped,readonly=off
