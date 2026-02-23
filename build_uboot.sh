#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_uboot.sh
    exit 0
fi

clone()
{
    ./clone.sh \
        u-boot \
        https://github.com/u-boot/u-boot \
        v2025.04
}

build()
{
    pushd $(readlink -f u-boot)
    rm -f .config
    make CROSS_COMPILE=aarch64-linux-gnu- qemu_arm64_defconfig
    scripts/config --set-val BOOTDELAY 1
    scripts/config --enable CC_OPTIMIZE_FOR_DEBUG
    intercept-build --append \
    make CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
    # duplicate elf to load it twice with gdb
    cp u-boot u-boot.relocated
    sed -i compile_commands.json -e 's/"cc"/"aarch64-linux-gnu-gcc"/'
    popd
}

clone
build
