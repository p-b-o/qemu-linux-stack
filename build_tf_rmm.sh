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
        https://github.com/TF-RMM/tf-rmm \
        481cb7f4 \
        patches/rmm-support-lower-pmu-versions.patch \
        patches/rmm-silence-Unhandled-read-write-regs-info.patch
}

build()
{
    pushd $(readlink -f tf-rmm)
    env CROSS_COMPILE=aarch64-linux-gnu- \
      cmake -DRMM_CONFIG=qemu_sbsa_defcfg \
      -DCMAKE_BUILD_TYPE=Release \
      -DLOG_LEVEL=40 \
      -S . -B build
    intercept-build --append \
    make -C build -j "$(nproc)"
    sed -i compile_commands.json -e 's/"cc"/"aarch64-linux-gnu-gcc"/'
    popd
}

clone
build
