#!/usr/bin/env bash

set -euo pipefail
set -x

if [ -z "${DISABLE_CONTAINER_CHECK:-}" ]; then
    ./container.sh ./web/check.sh
    exit 0
fi

pushd web

ace_version=v1.43.6
ace_dir=deps/ace-$ace_version
if [ ! -d $ace_dir ]; then
    git clone https://github.com/ajaxorg/ace --depth 1 \
        --single-branch --branch $ace_version $ace_dir
fi

# https://github.com/biomejs/biome
biome check --error-on-warnings --formatter-enabled=false ./*.js ./*.css
# config generated with tsc --init
# apt install node-typescript
tsc
# apt install mypy
mypy --strict ./uftrace-web-trace.py

# format
biome format --write ./*.js ./*.css
# apt install black
black ./uftrace-web-trace.py
