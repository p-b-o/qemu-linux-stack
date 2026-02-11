#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_slof.sh
    exit 0
fi

clone()
{
    rm -f slof
    url=https://gitlab.com/slof/slof
    version=qemu-slof-20251026
    src=slof-$version
    if [ ! -d $src ]; then
        rm -rf $src.tmp
        git clone $url --single-branch --branch $version --depth 1 $src.tmp
        mv $src.tmp $src
    fi
    ln -s $src slof
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
