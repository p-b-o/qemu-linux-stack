#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_hafnium.sh
    exit 0
fi

clone()
{
    rm -f hafnium
    url=https://github.com/TF-Hafnium/hafnium
    version=v2.14
    src=hafnium-$version
    if [ ! -d $src ]; then
        rm -rf $src.tmp
        git clone $url --single-branch --branch $version --depth 1 $src.tmp
        pushd $src.tmp
        git submodule update --init --depth 1 -j $(nproc)
        popd
        mv $src.tmp $src
    fi
    ln -s $src hafnium
}

build()
{
    pushd $(readlink -f hafnium)
    intercept-build --append \
    make PLATFORM=secure_qemu_aarch64 -j$(nproc)
    sed -i compile_commands.json -e 's/"cc"/"aarch64-linux-gnu-gcc"/'
    popd
}

clone
build
