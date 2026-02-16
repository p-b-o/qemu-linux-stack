#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_optee_client.sh
    exit 0
fi

clone()
{
    rm -f optee-client
    url=https://github.com/OP-TEE/optee_client.git
    version=4.9.0
    src=optee-client-$version
    if [ ! -d $src ]; then
        rm -rf $src.tmp
        git clone $url --single-branch --branch $version --depth 1 $src.tmp
        mv $src.tmp $src
    fi
    ln -s $src optee-client
}

build()
{
    pushd $(readlink -f optee-client)
    cmake -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc
    intercept-build --append \
    make all -j$(nproc)

    sed -i compile_commands.json -e 's/"cc"/"aarch64-linux-gnu-gcc"/'
    popd
}

clone
build
