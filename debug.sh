#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: qemu_hexagon_cmd"
    exit 1
fi

qemu_hexagon_cmd=$*

tmux_session()
{
    qemu_cmd="$*"
    unset TMUX
    tmux -L PATH \
    new-session -s qemu-linux bash -cx "set -x; $qemu_cmd || read" \; \
    split-window -h "./container.sh lldb -S lldbinit"
}

if [ -z "$(which tmux)" ]; then
    echo "debug.sh: tmux needs to be installed on your machine"
    exit 1
fi
tmux_session ./run.sh $qemu_hexagon_cmd -S -s
