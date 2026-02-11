#!/usr/bin/env bash

set -euo pipefail
set -x

if [ $# -lt 1 ]; then
    echo "usage: qemu_cmd"
    exit 1
fi

breakpoints()
{
    cat lldbinit-big-endian lldbinit-little-endian | grep '^b ' |
        sed -e 's/^b //'
}

# expected first frame when stopping on breakpoint $1
frame_pattern()
{
    case "$1" in
        -a\ 0x*) echo "^frame #0:.*0x0*${1#-a 0x}\b";;
        *) echo "^frame #0:.*\`$1\b";;
    esac
}

qemu_cmd=$*

tmp=$(mktemp -d)
env INIT=true ./run.sh $qemu_cmd -S -s &
qemu_pid=$!
trap "kill -9 $qemu_pid 2>/dev/null; rm -rf $tmp" EXIT

lldbtest=$tmp/test
output=$tmp/out

echo "command source lldbinit" > $lldbtest
breakpoints | while read -r bp; do
cat >> $lldbtest << EOF
frame info
c
EOF
done
echo "q" >> $lldbtest

./container.sh lldb-22 -S $lldbtest |& tee $output
wait $qemu_pid
trap "rm -rf $tmp" EXIT

breakpoints | while read -r bp; do
    grep "$(frame_pattern "$bp")" $output
done
