set remotetimeout 99999
target remote :1234

source ./gdb.py

add-symbol-file ./opensbi/build/platform/generic/firmware/fw_jump.elf 0x80000000
# sbi_init exists in kernel also, so restrict it to opensbi source
b lib/sbi/sbi_init.c:sbi_init

add-symbol-file ./linux/vmlinux
b start_kernel

c
