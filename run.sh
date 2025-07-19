#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: qemu_aarch64_cmd"
    exit 1
fi

[ -v INIT ] || INIT=/host/host.sh

mkdir -p out/EFI
cp -f out/Image ./out/EFI/Image
cat > ./out/EFI/startup.nsh << EOF
fs0:
Image nokaslr root=/dev/vda rw init=/init -- $INIT
EOF

# Need to cd to spdm_responder_emu folder so it can access keys
(cd out/spdm/ && ./spdm_responder_emu --trans PCI_DOE --slot_count 1)&
spdm_pid=$!
kill_spdm_emu()
{
    (kill $spdm_pid && wait $spdm_pid) || true
}
trap kill_spdm_emu EXIT

# wait for spdm_emu
sleep 1

dd if=/dev/urandom of=out/disk bs=2M count=1

"$@" \
-nodefaults \
-display none \
-serial mon:stdio \
-netdev user,id=vnet \
-device virtio-net-pci,netdev=vnet \
-M sbsa-ref \
-cpu max,x-rme=on \
-smp 1 \
-m 2G \
-drive file=out/SBSA_FLASH0.fd,format=raw,if=pflash \
-drive file=out/SBSA_FLASH1.fd,format=raw,if=pflash \
-drive file=fat:rw:out/EFI,format=raw \
-drive format=raw,file=./out/host.ext4,if=virtio \
-virtfs local,path=$(pwd)/,mount_tag=host,security_model=mapped,readonly=off \
-device pcie-root-port,id=root_port,chassis=1,slot=0 \
-drive id=disk,file=out/disk,if=none \
-device ahci,id=ahci,spdm_port=2323,bus=root_port \
-device ide-hd,drive=disk,bus=ahci.0 \

rm -rf out/EFI
rm -f out/disk
