#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: qemu_aarch64_cmd"
    exit 1
fi

set -x

vfio=disk_vfio
iommufd=disk_iommufd
dd if=/dev/random of=$vfio bs=512 count=1 status=none
dd if=/dev/random of=$iommufd bs=1024 count=1 status=none

[ -v INIT ] || INIT="/host/host.sh /host/$vfio /host/$iommufd" \

"$@" \
-nodefaults \
-display none \
-serial mon:stdio \
-netdev user,id=vnet \
-device virtio-net-pci,netdev=vnet \
-M virt,secure=on,virtualization=on,gic-version=3,iommu=smmuv3 \
-cpu max \
-smp 1 \
-m 8G \
-bios ./out/flash.bin \
-kernel ./out/Image.gz \
-drive format=raw,file=./out/host.ext4,if=virtio \
-append "nokaslr root=/dev/vda rw init=/init -- $INIT" \
-virtfs local,path=$(pwd)/,mount_tag=host,security_model=mapped,readonly=off \
-drive file=$vfio,if=none,id=vfio,format=raw \
-device nvme,serial=vfio,drive=vfio \
-drive file=$iommufd,if=none,id=iommufd,format=raw \
-device nvme,serial=iommufd,drive=iommufd

rm $vfio $iommufd
