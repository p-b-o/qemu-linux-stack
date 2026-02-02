#!/usr/bin/env bash

set -euo pipefail
set -x

echo "check /dev/vda is the disk we expect"
lsblk | grep vda | grep 20G

fio \
--ioengine=libaio \
--direct=1 \
--runtime=30 \
--ramp_time=10 \
--rw=randread \
--bs=4k \
--iodepth=128 \
--filename=/dev/vda \
--name=randread
