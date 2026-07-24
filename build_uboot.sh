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
        v2026.01
}

bootcommand()
{
    cat << EOF
setenv kernel_comp_addr_r 0x50000000
setenv kernel_comp_size 0x04000000
setenv kernel_addr_r 0x40400000 # device loader
setenv fdt_addr_r 0x40000000 # default addr, start of RAM
setenv optee_overlay_addr 0x40004000 # overlay addr set at optee build
setenv cmdline_addr 0x40300000 # set with qemu -device loader
fdt addr \${fdt_addr_r}
fdt resize 4096
fdt apply \${optee_overlay_addr} # overlay set at optee build
# fdt print
env import -t \${cmdline_addr} - bootargs
print bootargs
booti \${kernel_addr_r} - \${fdt_addr_r}
EOF
}

bootcommand_format()
{
    bootcommand | sed -e 's/#.*//' | tr '\n' ';'
}

build()
{

    pushd $(readlink -f u-boot)
    rm -f .config
    make CROSS_COMPILE=aarch64-linux-gnu- qemu_arm64_defconfig
    scripts/config --set-val BOOTDELAY 1
    scripts/config --enable CC_OPTIMIZE_FOR_DEBUG
    scripts/config --enable OF_LIBFDT_OVERLAY
    scripts/config --enable USE_COMMAND
    scripts/config --set-str BOOTCOMMAND "$(bootcommand_format)"
    intercept-build --append \
    make CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
    # duplicate elf to load it twice with gdb
    cp u-boot u-boot.relocated
    sed -i compile_commands.json -e 's/"cc/"aarch64-linux-gnu-gcc/'
    popd
}

clone
build
