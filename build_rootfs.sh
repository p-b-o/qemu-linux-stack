#!/usr/bin/env bash

set -euo pipefail
set -x

mkdir -p out

build()
{
    r=$1
    rm -f out/$r.ext4
    podman build -t build-linux-stack-$r \
        --build-context common=rootfs/common rootfs/$r
    podman run --rm -v $(pwd):$(pwd) build-linux-stack-$r \
        cp --sparse=always /rootfs.ext4 $(pwd)/out/$r.ext4
}

build host
