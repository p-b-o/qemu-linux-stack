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
        v2.14.0
}

build()
{
    pushd $(readlink -f arm-trusted-firmware)
    # tf-a is not very good to handle config changes, so simply clean it
    git clean -ffdx
    intercept-build --append \
    make PLAT=qemu QEMU_USE_GIC_DRIVER=QEMU_GICV3 \
         SPD=spmd \
         ENABLE_FEAT_SEL2=1 \
         SP_LAYOUT_FILE=../optee-build/qemu_v8/sp_layout.json \
         NEED_FDT=yes \
         BL32_RAM_LOCATION=tdram \
         ENABLE_FEAT_MTE2=2 \
         BRANCH_PROTECTION=1 \
         ENABLE_SME_FOR_NS=2 ENABLE_SME_FOR_SWD=1 \
         ENABLE_SVE_FOR_NS=2 ENABLE_SVE_FOR_SWD=1 \
         ENABLE_FEAT_FGT=2 ENABLE_FEAT_HCX=2 ENABLE_FEAT_ECV=2 \
         BL32=../hafnium/out/reference/secure_qemu_aarch64_clang/hafnium.bin \
         BL33=../u-boot/u-boot.bin \
         QEMU_TOS_FW_CONFIG_DTS=../optee-build/qemu_v8/spmc_el2_manifest.dts \
         QEMU_TB_FW_CONFIG_DTS=../optee-build/qemu_v8/tb_fw_config.dts \
         LOG_LEVEL=40 \
         DEBUG=1 \
         all fip -j$(nproc)
    dd if=build/qemu/debug/bl1.bin of=flash.bin bs=4096 conv=notrunc
    dd if=build/qemu/debug/fip.bin of=flash.bin seek=64 bs=4096 conv=notrunc
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
