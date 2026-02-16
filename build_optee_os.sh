#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_optee_os.sh
    exit 0
fi

clone()
{
    rm -f optee-os
    url=https://github.com/OP-TEE/optee_os.git
    version=4.9.0
    src=optee-os-$version
    if [ ! -d $src ]; then
        rm -rf $src.tmp
        git clone $url --single-branch --branch $version --depth 1 $src.tmp
        mv $src.tmp $src
    fi
    ln -s $src optee-os
}

build()
{
    # deactivate pauth to be able to trace execution
    pushd $(readlink -f optee-os)
    intercept-build --append \
    make all -j$(nproc) \
    PLATFORM=vexpress-qemu_armv8a \
    CFG_CORE_SEL2_SPMC=y \
    CFG_ARM_GICV3=y CFG_CORE_HAFNIUM_INTC=y \
    CFG_TZDRAM_START=0x0e304000 \
    CFG_TZDRAM_SIZE=0x00cfc000 \
    CFG_CORE_WORKAROUND_NSITR_CACHE_PRIME=n \
    DEBUG=1 \
    CFG_TA_PAUTH=n \
    CFG_CORE_PAUTH=n \
    CFG_MEMTAG=y \
    CFG_TEE_CORE_NB_CORE=1 \
    CFG_ARM64_core=y \
    CFG_USER_TA_TARGETS=ta_arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_core=aarch64-linux-gnu- \
    CROSS_COMPILE_ta_arm64=aarch64-linux-gnu- \
    CFG_TEE_CORE_LOG_LEVEL=3

    sed -i compile_commands.json -e 's/"cc"/"aarch64-linux-gnu-gcc"/'
    popd
}

clone
build
