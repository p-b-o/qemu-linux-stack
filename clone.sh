#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 3 ]; then
    echo "usage: name repository_url version [patches...]"
    exit 1
fi

name=$1;shift
url=$1;shift
version=$1;shift
patches="$@"
current_branch=$(git branch --show-current)

unique_identifier()
{
    echo "$url"
    echo "$version"
    echo "$current_branch"
    if [ "$patches" != "" ]; then
        cat $patches
    fi
}
id=$(unique_identifier | sha1sum | cut -c 1-9)

cache_identifier()
{
    echo "$url"
    echo "$version"
}
cache_id=$(cache_identifier | sha1sum | cut -c 1-9)

cache=$HOME/.cache/qemu-linux-stack/clone
mkdir -p $cache
cache=$cache/$cache_id

set -x
src=$name-$id

rm -f $name

if [ ! -d $src ]; then
    rm -rf $src.tmp
    if [ ! -d $cache ]; then
        rm -rf $cache.tmp
        git clone --single-branch --branch $version --depth 1 $url $cache.tmp ||
        git clone $url $cache.tmp
        pushd $cache.tmp
        git checkout $version
        git submodule update --init --depth 1 -j $(nproc)
        popd
        mv $cache.tmp $cache
    fi
    rsync -a $cache/ $src.tmp/

    pushd $src.tmp
    git checkout $version
    popd

    for patch in $patches; do
        git -C $src.tmp am $(readlink -f $patch)
    done

    pushd $src.tmp
    popd
    mv $src.tmp $src
fi

ln -s $src $name
