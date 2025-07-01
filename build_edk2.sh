#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_edk2.sh
    exit 0
fi

clone()
{
    rm -f edk2
    url=https://github.com/tianocore/edk2.git
    version=edk2-stable202505
    src=$version
    if [ ! -d $src ]; then
        rm -rf $src.tmp
        git clone $url --single-branch --branch $version --depth 1 $src.tmp
        pushd $src.tmp
        git submodule update --init --depth 1
        popd
        mv $src.tmp $src
    fi
    ln -s $src edk2
}

build()
{
    pushd $(readlink -f edk2)
    make -C BaseTools -j $(nproc)
    export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
    # always build in debug to enable traces
    intercept-build --append \
    bash -c ". edksetup.sh &&
    build -q -n $(nproc) -a AARCH64 -b DEBUG -t GCC5 -p ArmVirtPkg/ArmVirtQemuKernel.dsc"
    sed -i compile_commands.json -e 's/"cc"/"aarch64-linux-gnu-gcc"/'
    popd
}

clone
build
