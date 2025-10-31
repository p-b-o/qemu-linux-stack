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
    src=arm-trusted-firmware-$version-patch-tcr2-sctlr2-pie-gcs-smmu-sbsa-non-coherent-pas-da
    if [ ! -d $src ]; then
        rm -rf $src.tmp
        git clone $url --single-branch --branch $version --depth 1 $src.tmp
        pushd $src.tmp
        # https://git.codelinaro.org/linaro/dcap/tf-a/trusted-firmware-a/-/commits/alp12
        git am ../patches/arm-trusted-firmware-support-move-manifest-definition.patch
        git am ../patches/arm-trusted-firmware-add-pcie-root-information.patch
        git am ../patches/arm-trusted-firmware-add-stubs-for-IDE-key-management.patch
        git am ../patches/arm-trusted-firmware-support-FEAT_TCR2-and-FEAT-SCTLR2.patch
        # add pie-gcs support, even though it's not supported on RMM side for da
        # branch.
        git am ../patches/arm-trusted-firmware-support-PIE-GCS.patch
        # initialize smmuv3
        git am ../patches/arm-trusted-firmware-plat-qemu-initialize-smmuv3-with-RME.patch
        # other patches
        git am ../patches/arm-trusted-firmware-add-device-non-coherent-map.patch
        git am ../patches/arm-trusted-firmware-add-pas-for-pcie-mmio.patch
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
