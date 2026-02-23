#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_arm_trusted_firmware.sh
    exit 0
fi

clone()
{
    ./clone.sh \
        arm-trusted-firmware \
        https://github.com/ARM-software/arm-trusted-firmware \
        v2.14.0 \
        patches/arm-trusted-firmware-support-move-manifest-definition.patch \
        patches/arm-trusted-firmware-add-pcie-root-information.patch \
        patches/arm-trusted-firmware-add-stubs-for-IDE-key-management.patch \
        patches/arm-trusted-firmware-plat-qemu-initialize-smmuv3-with-RME.patch \
        patches/arm-trusted-firmware-add-device-non-coherent-map.patch \
        patches/arm-trusted-firmware-add-pas-for-pcie-mmio.patch
}

build()
{
    pushd $(readlink -f arm-trusted-firmware)
    # tf-a is not very good to handle config changes, so simply clean it
    git clean -ffdx
    # boot with edk2, as uboot does not seem to work with rme
    # https://trustedfirmware-a.readthedocs.io/en/latest/components/realm-management-extension.html#building-and-running-tf-a-with-rme
    intercept-build --append \
    make PLAT=qemu_sbsa \
         ENABLE_RME=1 \
         RMM=../tf-rmm/build/Debug/rmm.img \
         LOG_LEVEL=40 \
         DEBUG=1 \
         all fip -j$(nproc)
    sed -i compile_commands.json -e 's/"cc"/"aarch64-linux-gnu-gcc"/'
    popd
}

clone
build
