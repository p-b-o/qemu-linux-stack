#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: qemu_aarch64_cmd"
    exit 1
fi

set -x

cd /host

image_vfio=$1; shift
image_iommufd=$1; shift

# find disk from serial
dev_vfio=$(lsblk --nvme | grep vfio | cut -f 1 -d ' ')
dev_iommufd=$(lsblk --nvme | grep iommufd | cut -f 1 -d ' ')
pci_vfio=$(basename $(readlink -f /sys/block/$dev_vfio/../../../))
pci_iommufd=$(basename $(readlink -f /sys/block/$dev_iommufd/../../../))

for p in "$pci_vfio" "$pci_iommufd"; do
    if [ "$(cat /sys/bus/pci/devices/$p/driver_override)" == vfio-pci ]; then
        continue
    fi
    echo $p > /sys/bus/pci/drivers/nvme/unbind || bash
    echo vfio-pci > /sys/bus/pci/devices/$p/driver_override
    echo $p > /sys/bus/pci/drivers/vfio-pci/bind
done

[ -v INIT ] || INIT="bash -c \"diff /dev/nvme0n1 $image_vfio && diff /dev/nvme1n1 $image_iommufd\""

qemu-system-aarch64 \
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
-virtfs local,path=$(pwd)/,mount_tag=host,security_model=mapped,readonly=off \
-device vfio-pci,host=$pci_vfio \
-object iommufd,id=iommufd0 \
-device vfio-pci,host=$pci_iommufd,iommufd=iommufd0
