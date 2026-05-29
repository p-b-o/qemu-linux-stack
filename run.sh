#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: qemu_hexagon_cmd"
    exit 1
fi

set -x

[ -v INIT ] || INIT=

"$@" \
-serial mon:stdio \
-nographic \
-M virt \
-m 4G \
-kernel ./out/loadlinux \
-smp 1 \
-device loader,addr=0xa0000000,file=out/vmlinux.bin
