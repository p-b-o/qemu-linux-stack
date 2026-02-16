#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_optee_build.sh
    exit 0
fi

clone()
{
    ./clone.sh \
        optee-build \
        https://github.com/OP-TEE/build/ \
        4.9.0

    pushd optee-build
    sed -i 's#optee_os/out/arm/#optee-os/out/arm-plat-vexpress/#' qemu_v8/sp_layout.json
    popd
}

clone
