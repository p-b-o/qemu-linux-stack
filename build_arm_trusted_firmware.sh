#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_arm_trusted_firmware.sh
    exit 0
fi

clone()
{
    rm -f arm-trusted-firmware
    url=https://github.com/ARM-software/arm-trusted-firmware
    version=v2.13.0
    src=arm-trusted-firmware-$version-patch-tcr2-sctlr2-pie-gcs-release
    if [ ! -d $src ]; then
        rm -rf $src.tmp
        git clone $url --single-branch --branch $version --depth 1 $src.tmp
        pushd $src.tmp
        git am ../patches/arm-trusted-firmware-support-FEAT_TCR2-and-FEAT-SCTLR2.patch
        git am ../patches/arm-trusted-firmware-support-PIE-GCS.patch
        popd
        mv $src.tmp $src
    fi
    ln -s $src arm-trusted-firmware
}

build()
{
    pushd $(readlink -f arm-trusted-firmware)
    # tf-a is not very good to handle config changes, so simply clean it
    git clean -ffdx
    # boot with edk2, as uboot does not seem to work with rme
    # https://trustedfirmware-a.readthedocs.io/en/latest/components/realm-management-extension.html#building-and-running-tf-a-with-rme
    intercept-build --append \
    make PLAT=qemu QEMU_USE_GIC_DRIVER=QEMU_GICV3 \
         BL33=../edk2/Build/ArmVirtQemuKernel-AARCH64/DEBUG_GCC5/FV/QEMU_EFI.fd \
         ENABLE_RME=1 \
         RMM=../tf-rmm/build/Release/rmm.img \
         LOG_LEVEL=40 \
         all fip -j$(nproc)
    dd if=build/qemu/release/bl1.bin of=flash.bin bs=4096 conv=notrunc
    dd if=build/qemu/release/fip.bin of=flash.bin seek=64 bs=4096 conv=notrunc
    sed -i compile_commands.json -e 's/"cc"/"aarch64-linux-gnu-gcc"/'
    popd
}

output()
{
    mkdir -p out
    rsync ./arm-trusted-firmware/flash.bin out/flash.bin
}

clone
build
output
