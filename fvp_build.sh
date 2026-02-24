#!/usr/bin/env bash

set -euo pipefail
set -x

mkdir -p fvp
pushd fvp

../clone.sh \
    shrinkwrap \
    https://gitlab.arm.com/tooling/shrinkwrap \
    6980f587f4adc9771b305ed7112e3fed350ce7bb

../clone.sh \
    rmm \
    https://git.trustedfirmware.org/TF-RMM/tf-rmm.git \
    topics/da_alp12_v2

# https://git.trustedfirmware.org/plugins/gitiles/TF-RMM/tf-rmm.git/+/refs/heads/topics/da_alp12_v2/docs/getting_started/building-with-shrinkwrap.rst
pushd rmm
export PATH=${PWD}/../shrinkwrap/shrinkwrap:$PATH
export SHRINKWRAP_CONFIG=${PWD}/tools/shrinkwrap/configs
export WORKSPACE=${PWD}/../
export SHRINKWRAP_BUILD=${WORKSPACE}
export SHRINKWRAP_PACKAGE=${SHRINKWRAP_BUILD}/package

# need to install some dependencies:
# https://shrinkwrap.docs.arm.com/en/latest/userguide/quickstart.html#install-shrinkwrap
shrinkwrap --runtime podman build cca-3world.yaml --overlay=cca_da.yaml --btvar GUEST_ROOTFS='${artifact:BUILDROOT}' --btvar RMM_SRC=${PWD} --no-sync=rmm
popd

popd

./build_rootfs.sh
