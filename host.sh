#!/usr/bin/env bash

set -euo pipefail

cd /host

set -x

dmesg | grep -i optee
/host/out/tee-supplicant -d
ls /dev/tee*
