set remotetimeout 99999
target remote :1234

source ./gdb.py

add-symbol-file ./arm-trusted-firmware/build/qemu_sbsa/debug/bl1/bl1.elf
b bl1_main
add-symbol-file ./arm-trusted-firmware/build/qemu_sbsa/debug/bl2/bl2.elf
b bl2_main
add-symbol-file ./arm-trusted-firmware/build/qemu_sbsa/debug/bl31/bl31.elf
b bl31_main

# For rmm, we need to find loaded address (chosen by TF-A) + offset (build)
# Check for RMM address loaded by TF-A:
# $ ./run.sh qemu-system-aarch64 | grep 'Reserved RMM memory'
# INFO:    Reserved RMM memory [0x10000000000, 0x10042ffffff] in Device tree
# Check for offset in RMM image:
# ./build_rmm.sh |& grep 'offset of the RMM bin'
# INFO: The offset of the RMM bin is 118784 (0x1d000) bytes
add-symbol-file ./tf-rmm/build/Debug/rmm.elf 0x1000001d000
b rmm_main

# EDK2 directly prints add-symbol-file with expected offsets
# only DxeCore is added here
add-symbol-file ./edk2/Build/SbsaQemuRme/DEBUG_GCC5/AARCH64/MdeModulePkg/Core/Dxe/DxeMain/DEBUG/DxeCore.dll 0x1007F7CF000
b DxeMain

add-symbol-file ./linux/vmlinux
b start_kernel

c
