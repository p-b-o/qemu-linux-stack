#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_kernel.sh
    exit 0
fi

clone()
{
    rm -f linux
    url=https://gitlab.arm.com/linux-arm/linux-cca
    version=cca-host/v9
    src=linux_$(echo $version | tr '/' '_')
    if [ ! -d $src ]; then
        rm -rf $src.tmp
        git clone $url --single-branch --branch $version --depth 1 $src.tmp
        pushd $src.tmp
        git am ../patches/linux-include-linux-compiler-add-DEBUGGER-attribute-for-functions.patch
        popd
        mv $src.tmp $src
    fi
    ln -s $src linux
}

build()
{
    export CC_NO_DEBUG_MACROS=1

    pushd $(readlink -f linux)
    rm -f .config
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig -j$(nproc)
    # reduce number of timer interrupts
    scripts/config --disable CONFIG_HZ_250
    scripts/config --enable CONFIG_HZ_100
    # nvme
    scripts/config --enable BLK_DEV_NVME
    # iommufd
    # https://docs.kernel.org/driver-api/vfio.html#vfio-device-cdev
    scripts/config --enable IOMMUFD
    scripts/config --enable VFIO_DEVICE_CDEV
    scripts/config --enable ARM_SMMU_V3_IOMMUFD
    # # Enable the configfs-tsm driver that provides the attestation interface
    scripts/config --enable VIRT_DRIVERS
    scripts/config --enable ARM_CCA_GUEST

    # disable all modules
    sed -i -e 's/=m$/=n/' .config

    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig -j$(nproc)
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- all -j$(nproc)

    # compile commands
    ./scripts/clang-tools/gen_compile_commands.py
    sed -i ./compile_commands.json \
        -e 's/-femit-struct-debug-baseonly//' \
        -e 's/-fconserve-stack//' \
        -e 's/-fno-allow-store-data-races//' \
        -e 's/-mabi=lp64//' \
        -e 's/aarch64-linux-gnu-gcc/clang -target aarch64-pc-none-gnu -Wno-unknown-warning-option -enable-trivial-auto-var-init-zero-knowing-it-will-be-removed-from-clang/'

    popd

    unset CC_NO_DEBUG_MACROS
}

output()
{
    mkdir -p out
    # kvmtool is not able to boot a compressed kernel
    rsync ./linux/arch/arm64/boot/Image out/
}

clone
build
output
