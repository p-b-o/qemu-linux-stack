#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_optee_client.sh
    exit 0
fi

clone()
{
    ./clone.sh \
        optee-client \
        https://github.com/OP-TEE/optee_client.git \
        4.9.0
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

output()
{
    mkdir -p out
    cp ./optee-client/tee-supplicant/tee-supplicant out/tee-supplicant
}

clone
build
output
