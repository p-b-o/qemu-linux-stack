#!/usr/bin/env bash

set -euo pipefail

script_dir=$(dirname $(readlink -f $0))

if [ $# -lt 1 ]; then
    echo "usage: command"
    exit 1
fi

if [ -z "$(which tee)" ]; then
    echo "trace.sh: coreutils (tee) needs to be installed on your machine"
    exit 1
fi

if [ -z "$(which ts)" ]; then
    echo "trace.sh: moreutils (ts) needs to be installed on your machine"
    exit 1
fi

set -x

(uftrace record --clock realtime --srcline "$@" || true) |& ts "%.s" | tee exec.log

set +x

echo "----------------------------------------"
echo "execution log is available in ./exec.log"
echo "view trace with:"
echo "$script_dir/uftrace-web-viewer.sh ./exec.log"
