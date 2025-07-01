#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_kvmtool.sh
    exit 0
fi

clone()
{
    rm -f kvmtool
    url=https://gitlab.arm.com/linux-arm/kvmtool-cca
    version=cca/v7
    src=kvmtool_$(echo $version | tr '/' '_')
    if [ ! -d $src ]; then
        rm -rf $src.tmp
        git clone $url --single-branch --branch $version --depth 1 $src.tmp
        mv $src.tmp $src
    fi
    ln -s $src kvmtool
}

build()
{
    pushd $(readlink -f kvmtool)
    intercept-build --append \
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
    sed -i compile_commands.json -e 's/"cc"/"aarch64-linux-gnu-gcc"/'
    popd
}

output()
{
    mkdir -p out
    rsync ./kvmtool/lkvm out/
}

clone
build
output
