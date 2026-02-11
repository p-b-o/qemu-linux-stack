set remotetimeout 99999
target remote :1234

source ./gdb.py

add-symbol-file ./linux/vmlinux
b start_kernel

c
