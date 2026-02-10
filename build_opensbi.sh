#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_opensbi.sh
    exit 0
fi

clone()
{
    ./clone.sh \
        opensbi \
        https://github.com/riscv-software-src/opensbi \
        v1.8.1
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
