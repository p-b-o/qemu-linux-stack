#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: qemu_cmd"
    exit 1
fi

./container.sh true

echo "---------------------------------------------------------"
echo "Exit QEMU with Ctrl-a + x"
echo "Press F5 in VS Code to start debugging"
echo "---------------------------------------------------------"

env CONTAINER_NO_TTY=1 ./container.sh lldb-dap-22 --connection listen://127.0.0.1:4711 &
lldb_dap_pid=$!
trap "kill $lldb_dap_pid" EXIT

./run.sh "$@" -S -s
trap - EXIT

kill $lldb_dap_pid
wait $lldb_dap_pid
