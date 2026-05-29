#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: qemu_hexagon_cmd"
    exit 1
fi

set -x

[ -v INIT ] || INIT=

num_cpus=1

# append:
# - mem= is required, as linux hexagon does not read memory size from
# device tree but only from command line. Without it, it defaults to 64MB, which
# is too small to load the initramfs.
# - console is ttyAMA1 by default

exec "$@" \
-serial mon:stdio \
-nographic \
-netdev user,id=vnet \
-device virtio-net,netdev=vnet \
-M virt \
-m 4G \
-bios ./out/loadlinux \
-kernel ./out/vmlinux \
-drive format=raw,file=./out/host.ext4,if=virtio \
-smp $num_cpus \
-append "console=ttyAMA1 mem=892M maxcpus=$num_cpus nokaslr root=/dev/vda rw init=/init -- $INIT"
