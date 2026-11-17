#!/usr/bin/env bash

set -euo pipefail

script_dir=$(dirname $(readlink -f $0))

url=https://github.com/p-b-o/uftrace-web-viewer
version=$(git ls-remote $url refs/heads/master | cut -f 1)

pushd $script_dir > /dev/null
./clone.sh uftrace-web-viewer $url $version
popd > /dev/null

exec $script_dir/uftrace-web-viewer/perfetto.sh "$@"
