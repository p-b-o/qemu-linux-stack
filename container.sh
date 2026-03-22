#!/usr/bin/env bash

set -euo pipefail

script_dir=$(dirname $(readlink -f $0))

# build silently for 3 seconds, and restart if needed
timeout 3 podman build -q -t build-linux-stack - < $script_dir/Dockerfile ||
    podman build -t build-linux-stack - < $script_dir/Dockerfile

tty=-t
[ -v CONTAINER_NO_TTY ] && tty=
podman run \
    -i $tty --rm \
    -v $script_dir:$script_dir \
    -v $(pwd):$(pwd) \
    -w $(pwd) -v $HOME:$HOME -e HOME=$HOME \
    --init \
    --network host \
    --privileged \
    -e DISABLE_CONTAINER_CHECK=1 \
    build-linux-stack \
    "$@"
