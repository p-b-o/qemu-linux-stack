#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_spdm_emu.sh
    exit 0
fi

clone()
{
    ./clone.sh \
        spdm-emu \
        https://github.com/DMTF/spdm-emu \
        3.8.0
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
