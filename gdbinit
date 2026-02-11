set remotetimeout 99999
target remote :1234

source ./gdb.py

set endian little
add-symbol-file ./linux/vmlinux
b start_kernel

set endian big
add-symbol-file ./slof/board-qemu/slof/paflof.unstripped
#b engine
b *0x7db1e330
add-symbol-file ./slof/board-qemu/llfw/stage1.elf
#b early_c_entry

## zimage header, switching endianness
## https://github.com/torvalds/linux/blob/master/arch/powerpc/include/asm/ppc_asm.h#L836
## https://github.com/torvalds/linux/blob/master/arch/powerpc/boot/pseries-head.S
## zImage starting: loaded at 0x0000000000400000
#b *0x400000
#c
## rfid
#b *0x40002c
#c
## pass rfid
#si
#set endian little
#
#c
#
##add-symbol-file ./slof/board-qemu/slof/paflof.unstripped
#
##c
