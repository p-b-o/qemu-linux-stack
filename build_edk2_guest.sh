#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_edk2_guest.sh
    exit 0
fi

clone()
{
    rm -f edk2-cca-guest
    url=https://git.gitlab.arm.com/linux-arm/edk2-cca.git
    version=3223_arm_cca_v4
    src=edk2-$version-guest-device-assignment
    if [ ! -d $src ]; then
        rm -rf $src.tmp
        git clone $url --single-branch --branch $version --depth 1 $src.tmp
        pushd $src.tmp
        git submodule update --init --depth 1
        popd
        mv $src.tmp $src
    fi
    ln -s $src edk2-cca-guest
}

build()
{
    pushd $(readlink -f edk2-cca-guest)

    make -C BaseTools -j $(nproc)
    export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
    # always build in debug to enable traces
    # Set options to boot by default in EFI shell
    intercept-build --append \
    bash -c ". edksetup.sh &&
    build -q -n $(nproc) -a AARCH64 -b RELEASE -t GCC5 \
    -D ENABLE_RME \
    -p ArmVirtPkg/ArmVirtKvmTool.dsc \
    --pcd PcdUefiShellDefaultBootEnable=1 \
    --pcd PcdShellDefaultDelay=0 \
    --pcd PcdPlatformBootTimeOut=0"
    sed -i compile_commands.json -e 's/"cc"/"aarch64-linux-gnu-gcc"/'

    popd
}

output()
{
    mkdir -p out
    rsync edk2-cca-guest/Build/ArmVirtKvmTool-AARCH64/RELEASE_GCC5/FV/KVMTOOL_EFI.fd out/
}

clone
build
output
