#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_kvmtool.sh
    exit 0
fi

clone()
{
    rm -f kvmtool
    url=https://gitlab.arm.com/linux-arm/kvmtool-cca
    version=cca-1.1/da/proto/rmm-1.1-alp12/v1
    src=kvmtool_$(echo $version | tr '/' '_')-device-assignment
    if [ ! -d $src ]; then
        rm -rf $src.tmp
        git clone $url --single-branch --branch $version --depth 1 $src.tmp
        pushd $src.tmp
        # https://git.codelinaro.org/linaro/dcap/kvmtool/-/commits/alp12
        git am ../patches/kvmtool-irq-Avoid-concurrent-access-from-virtio-and-vfio-sub.patch
        popd
        mv $src.tmp $src
    fi
    ln -s $src kvmtool
}

build()
{
    pushd $(readlink -f kvmtool)
    intercept-build --append \
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
    sed -i compile_commands.json -e 's/"cc"/"aarch64-linux-gnu-gcc"/'
    popd
}

output()
{
    mkdir -p out
    rsync ./kvmtool/lkvm out/
}

clone
build
output
