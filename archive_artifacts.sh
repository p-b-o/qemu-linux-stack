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
# create a sparse archive with:
# - kernel
# - guest rootfs
# - host rootfs
./container.sh tar cJvfS $out run.sh io_benchmark.sh out/
du -h $out
