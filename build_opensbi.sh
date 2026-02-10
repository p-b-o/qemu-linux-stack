#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_opensbi.sh
    exit 0
fi

clone()
{
    rm -f opensbi
    url=https://github.com/riscv-software-src/opensbi
    version=v1.8.1
    src=opensbi-$version
    if [ ! -d $src ]; then
        rm -rf $src.tmp
        git clone $url --single-branch --branch $version --depth 1 $src.tmp
        mv $src.tmp $src
    fi
    ln -s $src opensbi
}

build()
{
    pushd $(readlink -f opensbi)
    intercept-build --append \
    make CROSS_COMPILE=riscv64-linux-gnu- \
         PLATFORM=generic BUILD_INFO=y DEBUG=1 \
         -j$(nproc)
    sed -i compile_commands.json -e 's/"cc"/"riscv64-linux-gnu-gcc"/'
    popd
}

output()
{
    mkdir -p out
    cp ./opensbi/build/platform/generic/firmware/fw_jump.bin out/opensbi.bin
}

clone
build
output
