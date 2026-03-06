#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: qemu_aarch64_cmd"
    exit 1
fi

set -x

[ -v INIT ] || INIT='/host/dom0.sh'

efi=out/efi
rm -rf $efi
mkdir -p $efi
cp out/xen.efi $efi/
cp out/Image.gz $efi/
cat > $efi/xen.cfg << EOF
[global]
default=dom0

[dom0]
# optee-build/qemu_v8/xen/xen.cfg
options=console=dtuart dom0_mem=1G
kernel=Image.gz arm64.nogcs console=hvc0 earlycon=xenboot nokaslr root=/dev/vdb rw init=/init -- $INIT
console=hvc0
EOF

# uboot will consider EFI partition is available as 'virtio 1', second disk
# CONFIG_BOOTCOMMAND='load virtio 0 0x60000000 /xen.efi; bootefi 0x60000000'
#
# second serial is for secure world, we alias it to stdout
# xen does not support smmuv3
"$@" \
-nodefaults \
-display none \
-serial mon:stdio \
-serial file:/dev/stdout \
-netdev user,id=vnet \
-device virtio-net-pci,netdev=vnet \
-M virt,secure=on,virtualization=on,gic-version=3 \
-cpu max \
-smp 1 \
-m 2G \
-bios ./out/flash.bin \
-drive format=raw,file=fat:rw:$efi \
-drive format=raw,file=./out/host.ext4,if=virtio \
-virtfs local,path=$(pwd)/,mount_tag=host,security_model=mapped,readonly=off
