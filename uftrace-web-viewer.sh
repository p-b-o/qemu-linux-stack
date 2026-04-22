#!/usr/bin/env bash

set -euo pipefail
set -x

script_dir=$(dirname $(readlink -f $0))

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    $script_dir/container.sh $script_dir/uftrace-web-viewer.sh "$@"
    exit 0
fi

web=$script_dir/web
data=$(pwd)/uftrace.data/web

if [ ! -d $data ]; then
    trap "rm -rf $data" EXIT
    $web/uftrace-web-trace.py "$@"
    trap - EXIT
fi

perfetto_version=qemu-linux-stack-v2
if [ ! -f perfetto/.$perfetto_version ]; then
    rm -rf perfetto.tar.gz* perfetto
    wget https://github.com/p-b-o/perfetto/releases/download/${perfetto_version}/perfetto.tar.gz
    tar --no-same-owner -xf perfetto.tar.gz
    rm perfetto.tar.gz
    touch perfetto/.$perfetto_version
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
echo "Trace available at: http://127.0.0.1:8000/?action=view-trace&trace=./trace.json"
echo "Trace available at: http://$(hostname):8000/?action=view-trace&trace=./trace.json"
echo --------------------------------------------------
python3 -m http.server > /dev/null
popd
