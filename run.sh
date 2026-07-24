#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: qemu_aarch64_cmd"
    exit 1
fi

set -x

[ -v INIT ] || INIT='/host/host.sh'

mkdir -p out/boot
trap "rm -rf out/boot" EXIT
echo "bootargs=nokaslr root=/dev/vda rw init=/init -- $INIT" > out/boot/cmdline

# optee-os will generate a dtb overlay, and thus, we need to manually apply it
# from u-boot, and boot kernel by hand. Thus why we load kernel and cmdline
# using device loader.
exec "$@" \
-nodefaults \
-display none \
-serial mon:stdio \
-serial file:/dev/stdout \
-netdev user,id=vnet \
-device virtio-net-pci,netdev=vnet \
-M virt,secure=on,virtualization=on,gic-version=2 \
-cpu max \
-smp 1 \
-m 8G \
-bios ./out/flash.bin \
-device 'loader,file=out/Image.gz,addr=0x40400000' \
-device 'loader,file=out/boot/cmdline,addr=0x40300000' \
-drive format=raw,file=./out/host.ext4,if=virtio \
-drive format=raw,file=fat:rw:out/boot \
-virtfs local,path=$(pwd)/,mount_tag=host,security_model=mapped,readonly=off
