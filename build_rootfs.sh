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
    container=$(podman create build-linux-stack-$r)
    # export a tar, and pass it to mke2fs directly
    podman export -o /dev/stdout $container |
        env CONTAINER_NO_TTY= \
        ./container.sh /sbin/mke2fs -t ext4 -d - out/$r.ext4.tmp 10g
    # re-sparse it, to get smaller file (mke2fs does not produce minimal files)
    ./container.sh cp --sparse=always out/$r.ext4.tmp out/$r.ext4
    rm out/$r.ext4.tmp
    podman rm -f $container
}

build host
