#!/usr/bin/env bash

set -euo pipefail

rm -rf out

if ! podman run -it --rm docker.io/debian:trixie true; then
    echo "error: podman must be installed on your machine"
    exit 1
fi

./container.sh ccache -M 50GB

echo '-------------------------------------------------------------------------'
./build_kernel.sh
echo '-------------------------------------------------------------------------'
./build_h2.sh
echo '-------------------------------------------------------------------------'

du -hc out/*
