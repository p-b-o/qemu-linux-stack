#!/usr/bin/env bash

set -euo pipefail

cd /host

set -x

# check optee is available
dmesg | grep -i optee
ls /dev/tee*

# copy ta app in expected location
rm -rf /lib/optee_armtz
mkdir -p /lib/optee_armtz
cp -r /host/out/optee_app/*.ta /lib/optee_armtz
cp -r /host/out/optee_test/*.ta /lib/optee_armtz
# launch user space daemon
/host/out/tee-supplicant --daemonize

# run (normal world) app
/host/out/optee_app/optee_example_hello_world

# run tests
/host/out/optee_test/xtest -t regression || true
