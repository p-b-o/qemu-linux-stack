#!/usr/bin/env bash

set -euo pipefail

rm -rf out

if ! podman run -it --rm docker.io/debian:trixie true; then
    echo "error: podman must be installed on your machine"
    exit 1
fi

# host != arm64
if ! podman run -it --rm --platform linux/arm64 docker.io/arm64v8/debian:trixie true; then
    echo "error: qemu-user-static must be installed on your machine"
    exit 1
fi

./container.sh ccache -M 50GB

./build_kernel.sh
echo '-------------------------------------------------------------------------'
./build_uboot.sh
echo '-------------------------------------------------------------------------'
# Various device tree for building optee
./build_optee_build.sh
echo '-------------------------------------------------------------------------'
# tee binary running at S-EL1
./build_optee_os.sh
echo '-------------------------------------------------------------------------'
# Normal world user space daemon and libraries for apps
./build_optee_client.sh
echo '-------------------------------------------------------------------------'
# Needs optee-client and optee-os
./build_optee_examples.sh
echo '-------------------------------------------------------------------------'
# Needs optee-client and optee-os
./build_optee_test.sh
echo '-------------------------------------------------------------------------'
./build_hafnium.sh
echo '-------------------------------------------------------------------------'
./build_arm_trusted_firmware.sh
echo '-------------------------------------------------------------------------'
./build_rootfs.sh
echo '-------------------------------------------------------------------------'

du -hc out/*
