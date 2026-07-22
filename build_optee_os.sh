#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_optee_os.sh
    exit 0
fi

clone()
{
    ./clone.sh \
        optee-os \
        https://github.com/OP-TEE/optee_os.git \
        4.9.0
}

build()
{
    # deactivate pauth to be able to trace execution
    pushd $(readlink -f optee-os)
    intercept-build --append \
    make all -j$(nproc) \
    PLATFORM=vexpress-qemu_armv8a \
    DEBUG=1 \
    CFG_ARM64_core=y \
    CFG_EXTERNAL_DTB_OVERLAY=y \
    CFG_USER_TA_TARGETS=ta_arm64 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_core=aarch64-linux-gnu- \
    CROSS_COMPILE_ta_arm64=aarch64-linux-gnu- \
    CFG_TEE_CORE_LOG_LEVEL=3

    sed -i compile_commands.json -e 's/"cc/"aarch64-linux-gnu-gcc/'
    popd
}

clone
build
