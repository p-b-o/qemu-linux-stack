#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_hafnium.sh
    exit 0
fi

clone()
{
    ./clone.sh \
        hafnium \
        https://github.com/TF-Hafnium/hafnium \
        v2.14 \
        patches/hafnium-enable-secure-smmuv3.patch

    pushd hafnium
    # deactivate mte
    sed -i -e 's/enable_mte = "1"/enable_mte = "0"/' project/reference/BUILD.gn
    popd
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
