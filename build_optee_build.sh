#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_optee_build.sh
    exit 0
fi

clone()
{
    rm -f optee-build
    url=https://github.com/OP-TEE/build/
    version=4.9.0
    src=optee-build-$version

    if [ ! -d $src ]; then
        rm -rf $src.tmp
        git clone $url --single-branch --branch $version --depth 1 $src.tmp
        pushd $src.tmp
        sed -i 's#optee_os/out/arm/#optee-os/out/arm-plat-vexpress/#' qemu_v8/sp_layout.json
        popd
        mv $src.tmp $src
    fi
    ln -s $src optee-build
}

clone
