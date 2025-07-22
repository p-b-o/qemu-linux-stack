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
    url=https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
    version=v6.17
    src=linux_${version}_x86_64
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
    make ARCH=x86_64 CROSS_COMPILE=x86_64-linux-gnu- defconfig -j$(nproc)
    # reduce number of timer interrupts
    scripts/config --disable CONFIG_NO_HZ
    scripts/config --disable CONFIG_HZ_1000
    scripts/config --enable CONFIG_HZ_100
    # nvme
    scripts/config --enable BLK_DEV_NVME
    # iommufd
    # https://docs.kernel.org/driver-api/vfio.html#vfio-device-cdev
    scripts/config --enable IOMMUFD
    scripts/config --enable VFIO_DEVICE_CDEV

    # disable all modules
    sed -i -e 's/=m$/=n/' .config

    make ARCH=x86_64 CROSS_COMPILE=x86_64-linux-gnu- olddefconfig -j$(nproc)
    make ARCH=x86_64 CROSS_COMPILE=x86_64-linux-gnu- all -j$(nproc)

    # compile commands
    ./scripts/clang-tools/gen_compile_commands.py
    sed -i ./compile_commands.json \
        -e 's/-femit-struct-debug-baseonly//' \
        -e 's/-fconserve-stack//' \
        -e 's/-fno-allow-store-data-races//' \
        -e 's/-mabi=lp64//' \
        -e 's/x86_64-linux-gnu-gcc/clang -target x86_64-pc-none-gnu -Wno-unknown-warning-option -enable-trivial-auto-var-init-zero-knowing-it-will-be-removed-from-clang/'

    popd

    unset CC_NO_DEBUG_MACROS
}

output()
{
    mkdir -p out
    rsync ./linux/arch/x86/boot/bzImage out/
}

clone
build
output
