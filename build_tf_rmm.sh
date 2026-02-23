#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_tf_rmm.sh
    exit 0
fi

clone()
{
    ./clone.sh \
        tf-rmm \
        https://review.trustedfirmware.org/TF-RMM/tf-rmm.git \
        431184a0b37 \
        patches/rmm-support-lower-pmu-versions.patch \
        patches/rmm-silence-Unhandled-read-write-regs-info.patch \
        patches/rmm-set-cmd-and-evt-queue-sizes-based-on-available-memory \
        patches/rmm-add-granules-for-non-coherent-devices.patch \
        patches/rmm-lib-dsm-Fix-dvsec-offset.patch \
        patches/rmm-lib-slot_buf-Fix-4-bytes-read-write-operations.patch
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
