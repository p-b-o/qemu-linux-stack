#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_h2.sh
    exit 0
fi

clone()
{
    ./clone.sh \
        h2 \
        https://github.com/qualcomm/hexagon-hypervisor.git \
        d414244 \
        patches/h2-boot-initialize-SHIFT-and-TCM_VAL-to-zero-on-non-.patch \
        patches/h2-capture-boot-registers-and-forward-a-DTB-address-.patch \
        patches/h2-restore-DEVICE_PAGE_SIZE-to-SIZE_4M-for-correct-s.patch \
        patches/h2-add-SHUTDOWN_AFTER_GUEST_EXIT-build-option.patch
}

build()
{
    pushd $(readlink -f h2)

    export PATH=/opt/hexagon-sdk/bin/:$PATH

    ARCHV=73
    intercept-build --append \
    make  -j$(nproc) \
    USE_PKW=0 ARCHV=$ARCHV TARGET=opt NULL_ANGEL_TRAP=1 SHUTDOWN_AFTER_GUEST_EXIT=1

    rsync -av artifacts/v${ARCHV}/opt/build/ ./

    INSTALLPATH=$(pwd)/artifacts/v${ARCHV}/opt/install
    intercept-build --append \
    make -C linux -j$(nproc) INSTALLPATH=$INSTALLPATH \
    USE_PKW=0 ARCHV=$ARCHV NO_LOAD=1 \
    NULL_ANGEL_TRAP=1 LINUX_LINK_ADDR=0xa0000000 \
    SHUTDOWN_AFTER_GUEST_EXIT=1 \
    loadlinux

    sed -i compile_commands.json -e 's/"cc/"hexagon-clang/'
    popd
}

output()
{
    mkdir -p out
    rsync h2/linux/loadlinux out/loadlinux
}

clone
build
output
