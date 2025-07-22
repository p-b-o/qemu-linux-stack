set remotetimeout 99999
target remote :1234

source ./gdb.py

add-symbol-file ./linux/vmlinux
b start_kernel

# During boot, EDK2 prints loading address for modules
# Loading PEIM at 0x000BFE81000 EntryPoint=0x000BFE97E5F DxeCore.efi
add-symbol-file edk2/Build/OvmfX64/DEBUG_GCC5/X64/MdeModulePkg/Core/Dxe/DxeMain/DEBUG/DxeCore.dll 0x000BFE81000
b DxeMain

c
