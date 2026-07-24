#!/usr/bin/env bash

set -euo pipefail

script_dir=$(dirname $(readlink -f $0))

context_hash=$(sha1sum $script_dir/Dockerfile | cut -f 1 -d ' ')
image=build-linux-stack-$context_hash
if ! podman image exists $image; then
    podman build --ulimit=nofile=65536:65536 -t $image -f $script_dir/Dockerfile
fi
podman tag $image build-linux-stack

tty=-t
[ -v CONTAINER_NO_TTY ] && tty=
exec podman run \
    -i $tty --rm \
    -v $script_dir:$script_dir \
    -v $(pwd):$(pwd) \
    -v /tmp:/tmp \
    -w $(pwd) -v $HOME:$HOME -e HOME=$HOME \
    --ulimit=nofile=65536:65536 \
    --init \
    --publish=127.0.0.1:4711:4711 \
    --publish=127.0.0.1:8000:8000 \
    --privileged \
    -e DISABLE_CONTAINER_CHECK=1 \
    build-linux-stack \
    "$@"
