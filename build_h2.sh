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
        https://github.com/qualcomm/hexagon-hypervisor \
        baf2a4d \
        patches/h2-Revert-Restore-polling-in-angel-trap.patch
}

build()
{
    pushd $(readlink -f h2)

    export PATH=/opt/hexagon-sdk/bin/:$PATH

    ARCHV=73
    intercept-build --append \
    make USE_PKW=0 ARCHV=$ARCHV TARGET=opt -j$(nproc)

    rsync -av artifacts/v${ARCHV}/opt/build/ ./

    INSTALLPATH=$(pwd)/artifacts/v${ARCHV}/opt/install
    intercept-build --append \
    make -C linux -j$(nproc) INSTALLPATH=$INSTALLPATH \
    USE_PKW=0 ARCHV=$ARCHV NO_LOAD=1 \
    LINUX_LINK_ADDR=0xa0000000 \
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
