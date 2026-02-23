#!/usr/bin/env bash

set -euo pipefail
set -x

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

src=$name-$id

rm -f $name

if [ ! -d $src ]; then
    rm -rf $src.tmp
    if git ls-remote $url $version --exit-code; then
        git clone $url --single-branch --branch $version --depth 1 $src.tmp
    else
        git clone $url $src.tmp
    fi

    pushd $src.tmp
    git checkout $version
    popd

    for patch in $patches; do
        git -C $src.tmp am $(readlink -f $patch)
    done

    pushd $src.tmp
    git submodule init
    git submodule update --depth 1 -j $(nproc)
    popd
    mv $src.tmp $src
fi

ln -s $src $name
