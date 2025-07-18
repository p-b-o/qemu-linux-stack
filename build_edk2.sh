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
    src=$version-sbsa
    if [ ! -d $src ]; then
        rm -rf $src.tmp
        git clone $url --single-branch --branch $version --depth 1 $src.tmp
        pushd $src.tmp
        git submodule update --init --depth 1
        popd
        mv $src.tmp $src
    fi
    ln -s $src edk2

    # clone platforms, which contains sbsa platform
    url=https://github.com/tianocore/edk2-platforms
    # version should match edk2 revision
    version=9562f2e64b2f817a7fd9455ce9dcd32d8500793d
    src=edk2/edk2-platforms
    if [ ! -d $src ]; then
        git clone https://github.com/tianocore/edk2-platforms --depth 1 $src
        pushd $src
        git fetch origin $version --depth 1
        git checkout $version
        popd
    fi
}

build()
{
    pushd $(readlink -f edk2)

    export PACKAGES_PATH=$(pwd):$(pwd)/edk2-platforms
    # copy bin from TF-A
    mkdir -p Platform/Qemu/Sbsa/
    cp -f ../arm-trusted-firmware/build/qemu_sbsa/release/*.bin Platform/Qemu/Sbsa/

    make -C BaseTools -j $(nproc)
    export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
    # always build in debug to enable traces
    # Set options to boot by default in EFI shell
    intercept-build --append \
    bash -c ". edksetup.sh &&
    build -q -n $(nproc) -a AARCH64 -b DEBUG -t GCC5 \
    -D ENABLE_RME \
    -p edk2-platforms/Platform/Qemu/SbsaQemu/SbsaQemu.dsc \
    --pcd PcdUefiShellDefaultBootEnable=1 \
    --pcd PcdShellDefaultDelay=0 \
    --pcd PcdPlatformBootTimeOut=0"
    sed -i compile_commands.json -e 's/"cc"/"aarch64-linux-gnu-gcc"/'
    truncate -s 256M Build/SbsaQemuRme/DEBUG_GCC5/FV/SBSA_FLASH*.fd
    popd
}

output()
{
    mkdir -p out
    rsync ./edk2/Build/SbsaQemuRme/DEBUG_GCC5/FV/SBSA_FLASH* out/
}

clone
build
output
