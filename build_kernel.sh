#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_kernel.sh
    exit 0
fi

clone()
{
    ./clone.sh \
        linux \
        https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git \
        v6.17 \
        patches/linux-include-linux-compiler-add-DEBUGGER-attribute-for-functions.patch
}

build()
{
    export CC_NO_DEBUG_MACROS=1

    pushd $(readlink -f linux)
    rm -f .config
    make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- defconfig -j$(nproc)
    # reduce number of timer interrupts
    scripts/config --disable CONFIG_HZ_250
    scripts/config --enable CONFIG_HZ_100
    # nvme
    scripts/config --enable BLK_DEV_NVME
    # /proc/sysrq-trigger
    scripts/config --enable CONFIG_MAGIC_SYSRQ
    # speed up boot by disabling ftrace
    scripts/config --disable CONFIG_FTRACE
    # iommufd
    # https://docs.kernel.org/driver-api/vfio.html#vfio-device-cdev
    scripts/config --enable IOMMUFD
    scripts/config --enable VFIO_DEVICE_CDEV

    # disable all modules
    sed -i -e 's/=m$/=n/' .config

    make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- olddefconfig -j$(nproc)
    make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- all -j$(nproc)

    # compile commands
    ./scripts/clang-tools/gen_compile_commands.py
    sed -i ./compile_commands.json \
        -e 's/-femit-struct-debug-baseonly//' \
        -e 's/-fconserve-stack//' \
        -e 's/-fno-allow-store-data-races//' \
        -e 's/-mabi=lp64//' \
        -e 's/riscv64-linux-gnu-gcc/clang -target riscv64-pc-none-gnu -Wno-unknown-warning-option -enable-trivial-auto-var-init-zero-knowing-it-will-be-removed-from-clang/'

    popd

    unset CC_NO_DEBUG_MACROS
}

output()
{
    mkdir -p out
    rsync ./linux/arch/riscv/boot/Image out/
}

clone
build
output
