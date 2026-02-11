#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_slof.sh
    exit 0
fi

clone()
{
    ./clone.sh \
        slof \
        https://gitlab.com/slof/slof \
        qemu-slof-20251026
}

build()
{
    pushd $(readlink -f slof)
    intercept-build --append \
    make CROSS=powerpc64-linux-gnu- V=1 -j$(nproc) qemu
    sed -i compile_commands.json -e 's/"cc"/"clang -target powerpc64-linux-gnu-gcc"/'
    popd
}

output()
{
    mkdir -p out
    cp ./slof/boot_rom.bin out/
}

clone
build
output
