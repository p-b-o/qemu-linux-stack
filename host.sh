#!/usr/bin/env bash

set -euo pipefail

cd /host

if [ $# -lt 1 ]; then
    echo "usage: qemu_hexagon_cmd"
    exit 1
fi

set -x

[ -v INIT ] || INIT=

"$@" \
-netdev user,id=vnet \
-device virtio-net-pci,netdev=vnet \
-M virt \
-display none \
-serial stdio \
-cpu host \
-enable-kvm \
-m 2G \
-kernel ./out/Image.gz \
-drive format=raw,file=./out/guest.ext4,if=virtio \
-append "nokaslr root=/dev/vda rw init=/init -- $INIT" \
-virtfs local,path=$(pwd)/,mount_tag=host,security_model=mapped,readonly=off
