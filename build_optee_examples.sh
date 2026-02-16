#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./build_optee_examples.sh
    exit 0
fi

clone()
{
    ./clone.sh \
        optee-examples \
        https://github.com/linaro-swg/optee_examples \
        4.9.0
}

build()
{
    tee_client=$(pwd)/optee-client/libteec
    ta_dev_kit=$(pwd)/optee-os/out/arm-plat-vexpress/export-ta_arm64

    pushd $(readlink -f optee-examples)
    intercept-build --append \
        make \
        CROSS_COMPILE=aarch64-linux-gnu- \
        LDADD=$tee_client/libteec.a \
        TEEC_EXPORT=$tee_client \
        TA_DEV_KIT_DIR=$ta_dev_kit \
        -j$(nproc)

    sed -i compile_commands.json -e 's/"cc"/"aarch64-linux-gnu-gcc"/'
    popd
}

output()
{
    rm -rf out/optee_app
    mkdir -p out/optee_app
    rsync -a ./optee-examples/hello_world/host/optee_example_hello_world \
             ./optee-examples/hello_world/ta/*.ta \
             out/optee_app/
}

clone
build
output
