#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./uftrace-web-viewer.sh "$@"
    exit 0
fi

web=$(pwd)/web
data=$(pwd)/uftrace.data/web

if [ ! -d $data ]; then
    trap "rm -rf $data" EXIT
    ./web/uftrace-web-trace.py "$@"
    trap - EXIT
fi

if [ ! -d perfetto ]; then
    rm -f perfetto.tar.gz*
    wget -q https://github.com/p-b-o/perfetto/releases/download/qemu-linux-stack/perfetto.tar.gz
    tar --no-same-owner -xf perfetto.tar.gz
    rm perfetto.tar.gz
fi

tmp=$(mktemp -d)
trap "rm -rf $tmp" EXIT
ln -s $(pwd)/perfetto $tmp/
ln -s $data/trace.json $tmp/
ln -s $data/traces $tmp/
ln -s $data/sources $tmp/
ln -s $web/style.css $tmp/
ln -s $web/uftrace-web-viewer.js $tmp/
ln -s $web/index.html $tmp/

pushd $tmp
set +x
echo --------------------------------------------------
echo "Trace available at: http://0.0.0.0:8000/?action=view-trace&trace=./trace.json"
echo --------------------------------------------------
python3 -m http.server > /dev/null
popd
