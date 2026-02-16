set remotetimeout 99999
target remote :1234

source ./gdb.py

add-symbol-file ./arm-trusted-firmware/build/qemu/debug/bl1/bl1.elf
b bl1_main
add-symbol-file ./arm-trusted-firmware/build/qemu/debug/bl2/bl2.elf
b bl2_main
add-symbol-file ./arm-trusted-firmware/build/qemu/debug/bl31/bl31.elf
b bl31_main
add-symbol-file ./hafnium/out/reference/secure_qemu_aarch64_clang/hafnium.elf
b image_entry
add-symbol-file ./optee-os/out/arm-plat-vexpress/core/tee.elf
b _start

# uboot map offset is given by TF-A during the boot:
# INFO:    BL31: Preparing for EL3 exit to normal world
# INFO:    Entry point address = 0x60000000
add-symbol-file ./u-boot/u-boot 0x60000000
b board_init_f
# https://github.com/u-boot/u-boot/blob/master/doc/README.arm-relocation
# => bdinfo
# relocaddr   = 0x000000023f6b6000
add-symbol-file ./u-boot/u-boot.relocated 0x000000023f6b6000

add-symbol-file ./linux/vmlinux
b start_kernel

c
