#!/usr/bin/env bash

set -euo pipefail

rm -rf out

if ! podman run -it --rm docker.io/debian:trixie true; then
    echo "error: podman must be installed on your machine"
    exit 1
fi

# host != ppc64le
if ! podman run -it --rm --platform linux/ppc64le docker.io/ppc64le/debian:trixie true; then
    echo "error: qemu-user-static must be installed on your machine"
    exit 1
fi

./container.sh ccache -M 50GB

./build_kernel.sh
echo '-------------------------------------------------------------------------'
./build_slof.sh
echo '-------------------------------------------------------------------------'
./build_rootfs.sh
echo '-------------------------------------------------------------------------'

du -hc out/*
