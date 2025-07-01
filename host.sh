#!/usr/bin/env bash

set -euo pipefail
set -x

[ -v INIT ] || INIT=

cd /host
./out/lkvm run \
    --realm -m 256m \
    --restricted_mem \
    --kernel ./out/Image \
    --disk ./out/guest.ext4 \
    --params "root=/dev/vda rw init=/init -- $INIT"
