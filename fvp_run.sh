#!/usr/bin/env bash

set -euo pipefail

if [ "$(which fuse2fs)" == "" ]; then
    echo "fuse2fs must be installed"
    exit 1
fi

if [ "$(which fusermount)" == "" ]; then
    echo "fuse3 must be installed"
    exit 1
fi

set -x

[ -v INIT ] || INIT=/host/host.sh

cd fvp

pushd rmm
export OUT=${PWD}/../../out
export PATH=${PWD}/../shrinkwrap/shrinkwrap:$PATH
export SHRINKWRAP_CONFIG=${PWD}/tools/shrinkwrap/configs
export WORKSPACE=${PWD}/../
export SHRINKWRAP_BUILD=${WORKSPACE}
export SHRINKWRAP_PACKAGE=${SHRINKWRAP_BUILD}/package

# https://shrinkwrap.docs.arm.com/en/latest/userguide/configstore/cca-3world.html
pushd $WORKSPACE/package/cca-3world/
mkdir -p mnt
cp -f $OUT/host.ext4 host.ext4
cp -f $OUT/guest.ext4 guest.ext4
fuse2fs -o fakeroot host.ext4 mnt
mkdir -p mnt/host/out
cp Image guest.ext4 lkvm mnt/host/out
cp $OUT/../host.sh mnt/host/
fusermount -u mnt
rm -rf mnt
popd

rootfs=$WORKSPACE/package/cca-3world/host.ext4

# FVP comes from container shrinkwraptool/base-slim:2026.3.0.dev0
# /tools/Base_RevC_AEMvA_pkg/models/Linux64_GCC-9.3/

export PATH
cat > FVP_Base_RevC-2xAEMvA << EOF
#!/usr/bin/env bash
echo FVP_Base_RevC-2xAEMvA "\$@" | tr ' ' '\n' | sed -e 's/$/ \\\\/' > fvp_command.txt
echo >> fvp_command.txt
EOF
chmod +x FVP_Base_RevC-2xAEMvA

set +x
echo "-------------------------------------------------------------"
# print fvp command line first
env PATH=$(pwd)/:$PATH \
shrinkwrap --runtime=null run cca-3world.yaml --overlay=cca_da.yaml \
    --rtvar ROOTFS=$rootfs \
    --rtvar CMDLINE="nokaslr root=/dev/vda rw init=/init -- $INIT"

cat fvp_command.txt

echo "-------------------------------------------------------------"
echo "exit with ctrl + ]"
echo "-------------------------------------------------------------"

# run fvp with runtime podman. This is needed else console stdout does not get
# printed. FVP uses 4 telnet for output and shrinkwrap deals with all this by
# itself.
set -x
shrinkwrap --runtime=podman run cca-3world.yaml --overlay=cca_da.yaml \
    --rtvar ROOTFS=$rootfs \
    --rtvar CMDLINE="nokaslr root=/dev/vda rw init=/init -- $INIT"
