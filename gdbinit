set remotetimeout 99999
target remote :1234

source ./gdb.py

add-symbol-file ./arm-trusted-firmware/build/qemu/release/bl1/bl1.elf
b bl1_main
add-symbol-file ./arm-trusted-firmware/build/qemu/release/bl2/bl2.elf
b bl2_main
add-symbol-file ./arm-trusted-firmware/build/qemu/release/bl31/bl31.elf
b bl31_main

# For rmm, we need to find loaded address (chosen by TF-A) + offset (build)
# Check for RMM address loaded by TF-A:
# $ ./run.sh qemu-system-aarch64 | grep 'Reserved RMM memory'
# Reserved RMM memory [0x40100000, 0x418fffff] in Device tree
# Check for offset in RMM image:
# ./build_rmm.sh |& grep 'offset of the RMM core'
# 0x60000
add-symbol-file ./tf-rmm/build/Release/rmm.elf 0x40160000
b rmm_main

# EDK2 directly prints add-symbol-file with expected offsets
# only DxeCore is added here
add-symbol-file edk2/Build/ArmVirtQemuKernel-AARCH64/DEBUG_GCC5/AARCH64/MdeModulePkg/Core/Dxe/DxeMain/DEBUG/DxeCore.dll 0xBF2BE000
b DxeMain

add-symbol-file ./linux/vmlinux
b start_kernel

c
