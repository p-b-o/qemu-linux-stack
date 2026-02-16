#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_optee_test.sh
    exit 0
fi

clone()
{
    ./clone.sh \
        optee-test \
        https://github.com/OP-TEE/optee_test/ \
        4.9.0 \
        patches/optee-test-fix-paths-for-teec-and-ckteec.patch
}

build()
{
    tee_client=$(pwd)/optee-client/libteec
    ta_dev_kit=$(pwd)/optee-os/out/arm-plat-vexpress/export-ta_arm64

    pushd $(readlink -f optee-test)
    intercept-build --append \
        make \
        CROSS_COMPILE=aarch64-linux-gnu- \
        OPTEE_CLIENT_EXPORT=$tee_client \
        TA_DEV_KIT_DIR=$ta_dev_kit \
        -j$(nproc)

    sed -i compile_commands.json -e 's/"cc"/"aarch64-linux-gnu-gcc"/'
    popd
}

output()
{
    rm -rf out/optee_test
    mkdir -p out/optee_test
    rsync -a ./optee-test/out/xtest/xtest \
             ./optee-test/out/ta/*/*.ta \
             out/optee_test
}

clone
build
output
