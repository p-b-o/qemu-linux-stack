#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_xen.sh
    exit 0
fi

clone()
{
    ./clone.sh \
        xen \
        https://github.com/xen-project/xen \
        RELEASE-4.21.0
}

build()
{
    pushd $(readlink -f xen)

    export CC_NO_DEBUG_MACROS=1

    pushd xen
    cp ../../optee-build/kconfigs/xen.conf .
    cp ../../optee-build/kconfigs/xen_debug.conf .
    make XEN_TARGET_ARCH=arm64 defconfig -j$(nproc)
    # optee-build/kconfigs/xen.conf
    # optee-build/kconfigs/xen_debug.conf
    cat > extra_config << EOF
# optee-build/kconfigs/xen.conf
CONFIG_UNSUPPORTED=y
CONFIG_TEE=y
CONFIG_OPTEE=y
CONFIG_FFA=y
CONFIG_SCHED_CREDIT2_DEFAULT=y
# optee-build/kconfigs/xen_debug.conf
CONFIG_DEBUG=y
CONFIG_DEBUG_INFO=y
CONFIG_DEBUG_LOCKS=y
CONFIG_VERBOSE_DEBUG=y
CONFIG_FRAME_POINTER=y
EOF
    env XEN_TARGET_ARCH=arm64 tools/kconfig/merge_config.sh \
        .config extra_config
    popd

    intercept-build --append \
    make dist-xen -j$(nproc) \
    XEN_TARGET_ARCH=arm64 \
    CROSS_COMPILE="aarch64-linux-gnu-"

    sed -i compile_commands.json -e 's/"cc"/"aarch64-linux-gnu-gcc"/'
    popd

    unset CC_NO_DEBUG_MACROS
}

output()
{
    mkdir -p out
    rsync xen/xen/xen out/xen.efi
}

clone
build
output
