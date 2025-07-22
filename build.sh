#!/usr/bin/env bash

set -euo pipefail

rm -rf out

if ! podman run -it --rm docker.io/debian:trixie true; then
    echo "error: podman must be installed on your machine"
    exit 1
fi

# host != amd64
if ! podman run -it --rm --platform linux/amd64 docker.io/amd64/debian:trixie true; then
    echo "error: qemu-user-static must be installed on your machine"
    exit 1
fi

./container.sh ccache -M 50GB

./build_kernel.sh
echo '-------------------------------------------------------------------------'
./build_edk2.sh
echo '-------------------------------------------------------------------------'
./build_rootfs.sh
echo '-------------------------------------------------------------------------'

du -hc out/*
