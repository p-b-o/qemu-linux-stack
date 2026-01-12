#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_tf_rmm.sh
    exit 0
fi

clone()
{
    rm -f tf-rmm
    url=https://review.trustedfirmware.org/TF-RMM/tf-rmm.git
    version=topics/da_alp12_v2
    src=tf-rmm-$(echo "$version" | tr '/' '_')-pmu-versions-cmd-queue-granule-sbsa-device-assignment
    if [ ! -d $src ]; then
        rm -rf $src.tmp
        git clone $url --single-branch --branch $version --depth 1 $src.tmp
        pushd $src.tmp
        git checkout $version
        git submodule update --init --depth 1
        git am ../patches/rmm-support-lower-pmu-versions.patch
        git am ../patches/rmm-arm-smmuv3-update-base-for-qemu.patch
        git am ../patches/rmm-set-cmd-and-evt-queue-sizes-based-on-available-memory
        git am ../patches/rmm-add-granules-for-non-coherent-devices.patch
        git am ../patches/rmm-silence-Unhandled-read-write-regs-info.patch
        popd
        mv $src.tmp $src
    fi
    ln -s $src tf-rmm
}

build()
{
    pushd $(readlink -f tf-rmm)
    env CROSS_COMPILE=aarch64-linux-gnu- \
      cmake -DRMM_CONFIG=qemu_sbsa_defcfg \
      -DCMAKE_BUILD_TYPE=Debug \
      -DLOG_LEVEL=40 \
      -DRMM_V1_1=ON \
      -S . -B build
    intercept-build --append \
    make -C build -j "$(nproc)"
    sed -i compile_commands.json -e 's/"cc"/"aarch64-linux-gnu-gcc"/'
    popd
}

clone
build
