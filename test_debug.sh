#!/usr/bin/env bash

set -euo pipefail
set -x

if [ $# -lt 1 ]; then
    echo "usage: qemu_cmd"
    exit 1
fi

breakpoints()
{
    cat lldbinit | grep '^b ' | sed -e 's/^b //'
}

qemu_cmd=$*

env INIT=true ./run.sh $qemu_cmd -S -s &
qemu_pid=$!
trap "kill -9 $qemu_pid 2>/dev/null" EXIT

tmp=$(mktemp -d)
trap "rm -rf $tmp" EXIT
lldbtest=$tmp/test
output=$tmp/out

echo "command source lldbinit" > $lldbtest
for bp in $(breakpoints); do
cat >> $lldbtest << EOF
frame info
c
EOF
done
echo "q" >> $lldbtest

./container.sh lldb-22 -S $lldbtest |& tee $output
trap - EXIT
wait $qemu_pid

for bp in $(breakpoints); do
    grep "^frame #0:.*$bp" $output
done
