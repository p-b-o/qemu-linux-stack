#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_image.sh
    exit 0
fi

build()
{
    efi=out/image/EFI/
    efi_image=out/image/efi.fat
    disk=out/image.img
    rm -rf $efi $efi_image $disk
    mkdir -p $efi/BOOT

    rootfs_size=$(du --bytes out/host.ext4 | cut -f 1)
    rootfs_size=$(((rootfs_size / 1024 / 1024) + 1))
    efi_size=512
    efi_offset=1
    end_padding=10
    total_size=$((efi_offset + efi_size + rootfs_size + end_padding))

    efi_start=$efi_offset
    efi_end=$((efi_start + efi_size))
    rootfs_start=$efi_end
    rootfs_end=$((rootfs_start + rootfs_size + 1))
    
    # prepare disk
    dd if=/dev/zero of=$disk bs=1M count=$total_size conv=sparse
    parted -s $disk mklabel gpt
    /usr/sbin/parted -s $disk mkpart ESP fat32 ${efi_start}MiB ${efi_end}MiB
    /usr/sbin/parted -s $disk mkpart ext4 ${rootfs_start}MiB ${rootfs_end}MiB
    /usr/sbin/parted -s $disk set 1 esp on
    /usr/sbin/fdisk -l $disk -o +UUID
    rootfs_partition=${disk}2
    rootfs_uuid=$(/usr/sbin/fdisk -l $disk -o +UUID |
                  grep $rootfs_partition | awk '{print $NF}')

    # copy refind files
    rsync -a /refind/ $efi/BOOT
    # set refind EFI as UEFI Fallback file
    mv $efi/BOOT/refind_x64.efi $efi/BOOT/BOOTx64.efi
    # copy kernel
    rsync -a out/bzImage $efi/bzImage.efi

    cat > $efi/BOOT/refind.conf << EOF
scan_driver_dirs EFI/BOOT/drivers_x64
timeout 5

menuentry Linux {
    icon EFI/BOOT/icons/os_linux.png
    loader EFI/bzImage.efi
    options "console=ttyS0 root=PARTUUID=$rootfs_uuid rw init=/init"
}
EOF

    # generate EFI partition
    dd if=/dev/zero of=$efi_image bs=1M count=$((efi_size))
    /usr/sbin/mkfs.fat -F 32 --mbr=no $efi_image
    mcopy -s -i $efi_image $efi ::

    # write partitions to disk
    dd if=$efi_image of=$disk seek=$((efi_start * 1024 * 1024))B \
        bs=1M count=${efi_size} conv=notrunc,sparse
    dd if=out/host.ext4 of=$disk seek=$((rootfs_start * 1024 * 1024))B \
        bs=1M count=${rootfs_size} conv=notrunc,sparse

    rm -rf out/image
}

build
