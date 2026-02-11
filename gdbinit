set remotetimeout 99999
target remote :1234

source ./gdb.py

set endian little
add-symbol-file ./linux/vmlinux
b start_kernel

set endian big
add-symbol-file ./slof/board-qemu/llfw/stage1.elf
b early_c_entry
add-symbol-file ./slof/board-qemu/slof/paflof.unstripped 0x7daf0200
# found offset from .patch_broken_sc1 (with a . prefix) (ofw_start calls it first)
# - find diff between runtime and symbol in file: 0x7daf9310 - 0xe109310
# - add text section offset (readelf -S): + 0xe100200
# b engine

# zimage header, switching endianness
# https://github.com/torvalds/linux/blob/master/arch/powerpc/include/asm/ppc_asm.h#L836
# https://github.com/torvalds/linux/blob/master/arch/powerpc/boot/pseries-head.S
# zImage starting: loaded at 0x0000000000400000
# b *0x400000
# step until 'rfid' instruction switching endianness (0x40002c)
#b *0x40002c
# break on next instruction and set endianness
b *0x40059c
commands
c
end
b *0x9c05400000000000
commands
set endian little
c
end

c
