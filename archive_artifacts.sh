#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "usage: out_tar_xz"
    exit 1
fi

out=$1; shift

if ! [[ "$out" =~ .*.tar.xz ]]; then
    echo "$out should be a .tar.xz archive"
    exit 1
fi

du -hc out/*
<<<<<<< HEAD
# create a sparse archive
./container.sh tar cJvfS $out run.sh host.sh out/
||||||| parent of ffce600 (x86_64: edk2 + linux + ubuntu)
# create a sparse archive with:
# - run.sh/host.sh scripts
# - kernel
# - guest rootfs
# - host rootfs
./container.sh tar cJvfS $out run.sh host.sh out/
=======
# create a sparse archive with:
# - kernel
# - guest rootfs
# - host rootfs
./container.sh tar cJvfS $out run.sh out/
>>>>>>> ffce600 (x86_64: edk2 + linux + ubuntu)
du -h $out
