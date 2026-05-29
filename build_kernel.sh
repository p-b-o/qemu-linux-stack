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
        https://git.kernel.org/pub/scm/linux/kernel/git/bcain/linux.git \
        bcain/boot_qemu \
        patches/linux-include-linux-compiler-add-DEBUGGER-attribute-for-functions.patch
}

build()
{
    export CC_NO_DEBUG_MACROS=1

    flags="ARCH=hexagon CC=hexagon-unknown-linux-musl-clang LLVM=1 LLVM_IAS=1 HOSTCC=gcc"
    pushd $(readlink -f linux)
    rm -f .config
    make $flags qemu_defconfig -j$(nproc)

    if [ ! -f rootfs.cpio ]; then
        wget https://artifacts.codelinaro.org/artifactory/codelinaro-toolchain-for-hexagon/22.1.4_/rootfs.cpio -O dl
        mv dl rootfs.cpio
    fi

    ./scripts/config --set-str CONFIG_INITRAMFS_SOURCE $(pwd)/../rootfs/rootfs.cpio
    ./scripts/config --enable CONFIG_INITRAMFS_COMPRESSION_NONE

    ## disable all modules
    sed -i -e 's/=m$/=n/' .config

    make $flags olddefconfig -j$(nproc)
    make $flags vmlinux -j$(nproc)

    llvm-objcopy -O binary vmlinux vmlinux.bin

    # compile commands
    ./scripts/clang-tools/gen_compile_commands.py
    popd

    unset CC_NO_DEBUG_MACROS
}

output()
{
    mkdir -p out
    rsync ./linux/vmlinux.bin out/vmlinux.bin
}

clone
build
output
