#!/usr/bin/env bash

set -euo pipefail

cd /host

set -x

dtc -I fs /sys/firmware/devicetree/base | grep -i -C 5 optee
dmesg | grep -i -C 5 optee
/host/out/tee-supplicant -d
ls /dev/tee*
