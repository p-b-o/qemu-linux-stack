#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_spdm_emu.sh
    exit 0
fi

clone()
{
    rm -f spdm-emu
    url=https://github.com/DMTF/spdm-emu
    version=3.8.0
    src=spdm-emu-$version
    if [ ! -d $src ]; then
        rm -rf $src.tmp
        git clone $url --single-branch --branch $version --depth 1 $src.tmp
        pushd $src.tmp
        git submodule update --init --recursive --depth 1
        popd
        mv $src.tmp $src
    fi
    ln -s $src spdm-emu
}

build()
{
    pushd $(readlink -f spdm-emu)
    cmake -DARCH=x64 -DTOOLCHAIN=GCC -DTARGET=Debug -DCRYPTO=openssl -S . -B build
    pushd build
    make copy_sample_key
    intercept-build --append \
    make -j $(nproc)
    sed -i compile_commands.json -e 's/"cc"/"aarch64-linux-gnu-gcc"/'
    popd
    popd
}

output()
{
    mkdir -p out
    rm -rf out/spdm
    rsync -a ./spdm-emu/build/bin/spdm_responder_emu \
             ./spdm-emu/build/bin/ecp* \
             ./spdm-emu/build/bin/rsa* \
             out/spdm/
}

clone
build
output
