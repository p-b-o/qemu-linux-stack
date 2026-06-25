#!/usr/bin/env bash

set -euo pipefail
set -x

if [ $# -lt 1 ]; then
    echo "usage: qemu_cmd"
    exit 1
fi

qemu_cmd=$*

env INIT=true ./run.sh $qemu_cmd -S -s &
qemu_pid=$!
trap "kill -9 $qemu_pid 2>/dev/null" EXIT

./container.sh lldb-22 -S lldbtest
trap - EXIT
wait $qemu_pid
