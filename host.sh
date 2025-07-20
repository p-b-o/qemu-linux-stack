#!/usr/bin/env bash

set -euo pipefail
set -x

[ -v INIT ] || INIT=

lspci -vvv

disk_hash=$(md5sum < /dev/sda | cut -f 1 -d ' ')
if [ -f /host/out/disk ]; then
    diff <(echo $disk_hash) <(md5sum /host/out/disk | cut -f 1 -d ' ')
fi

# find device to connect
sys_tsm_connect=$(find /sys | grep tsm/connect | tail -n 1)
[ -f "$sys_tsm_connect" ]
# /sys/devices/pci0000:00/0000:00:04.0/0000:01:00.0/tsm/connect -> 0000:01:00.0
dev=$(basename $(realpath $(dirname $sys_tsm_connect)/..))
echo $dev

# bind it to tsm
echo $dev > /sys/bus/pci/devices/$dev/driver/unbind
echo vfio-pci > /sys/bus/pci/devices/$dev/driver_override
echo $dev > /sys/bus/pci/drivers_probe
echo tsm0 > /sys/bus/pci/devices/$dev/tsm/connect

# prepare nested guest commands
mkdir -p guest
mount /host/out/guest.ext4 guest
cat > guest/da_connect.sh << EOF
#!/usr/bin/env bash
set -euo pipefail
set -x

lspci -vvv

diff <(echo $disk_hash) <(md5sum /dev/sda | cut -f 1 -d ' ')
echo "unbind device"
echo 0000:00:00.0 > /sys/bus/pci/devices/0000:00:00.0/driver/unbind
echo "lock device"
echo tsm0 > /sys/bus/pci/devices/0000:00:00.0/tsm/lock
echo "set TDISP run state"
echo 1 > /sys/bus/pci/devices/0000:00:00.0/tsm/accept

echo "load driver"
echo 0000:00:00.0 > /sys/bus/pci/drivers_probe

[ -e /dev/sda ] || sleep 1
[ -e /dev/sda ] || sleep 1
[ -e /dev/sda ] || sleep 1
[ -e /dev/sda ] || sleep 1
[ -e /dev/sda ] || sleep 1
[ -e /dev/sda ]
diff <(echo $disk_hash) <(md5sum /dev/sda | cut -f 1 -d ' ')
EOF
chmod +x guest/da_connect.sh
umount guest
rmdir guest

INIT=${INIT:-/da_connect.sh}

cd /host
./out/lkvm run \
    --realm \
    -m 256 \
    --loglevel=debug \
    --debug-mmio \
    --debug-ioport \
    --kernel /host/out/Image \
    --disk /host/out/guest.ext4 \
    --iommufd-vdevice \
    --vfio-pci $dev \
    --params "root=/dev/vda rw init=/init -- $INIT"

## rebind pci device to ahci
#echo $dev > /sys/bus/pci/devices/$dev/driver/unbind
#echo ahci > /sys/bus/pci/devices/$dev/driver_override
#echo $dev > /sys/bus/pci/drivers_probe
#
#[ -e /dev/sda ] || sleep 1
#[ -e /dev/sda ] || sleep 1
#[ -e /dev/sda ] || sleep 1
#[ -e /dev/sda ] || sleep 1
#[ -e /dev/sda ] || sleep 1
#[ -e /dev/sda ]
#diff <(echo $disk_hash) <(md5sum /dev/sda | cut -f 1 -d ' ')
