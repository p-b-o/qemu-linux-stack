"""
Debug ppc64 QEMU gdbstub with lldb, following cpu endianness switches.

QEMU sends registers using current cpu endianness, while lldb byte order is
fixed by target triple, and can't be changed at runtime. SLOF runs big-endian,
while Linux runs little-endian, so we need to reconnect with a new target every
time cpu switches endianness.

Detaching (D packet) resumes the VM, so we drop connection instead, which keeps
VM stopped until next connection.

Usage:
  command script import lldb_ppc64.py
  ppc64-connect localhost:1234

After every (re)connection, lldbinit-big-endian or lldbinit-little-endian is
sourced to load symbols and set breakpoints.
"""

import lldb
import os
import socket

TRIPLE = {
    False: 'powerpc64-unknown-linux-gnu',
    True: 'powerpc64le-unknown-linux-gnu',
}
INIT_FILE = {
    False: 'lldbinit-big-endian',
    True: 'lldbinit-little-endian',
}

gdbstub = None


def run(debugger, cmd):
    res = lldb.SBCommandReturnObject()
    debugger.GetCommandInterpreter().HandleCommand(cmd, res)
    print(res.GetOutput(), end='')
    if not res.Succeeded():
        raise RuntimeError(f'{cmd}: {res.GetError().strip()}')


def target_little_endian(target):
    return target.GetByteOrder() == lldb.eByteOrderLittle


def cpu_little_endian(target):
    frame = target.GetProcess().GetSelectedThread().GetFrameAtIndex(0)
    msr = frame.FindRegister('msr').GetValueAsUnsigned()
    order = 'little' if target_little_endian(target) else 'big'
    # Get back bytes as sent by QEMU (cpu byte order).
    # If cpu is little-endian, first byte is the least significant one, which
    # contains MSR_LE. Else, it's the most significant one, where bit 0 (MSR
    # bit 56) is always 0.
    return bool(msr.to_bytes(8, order)[0] & 1)


def drop_connection(port):
    for fd in os.listdir('/proc/self/fd'):
        try:
            if not os.readlink(f'/proc/self/fd/{fd}').startswith('socket:'):
                continue
            s = socket.socket(fileno=os.dup(int(fd)))
        except OSError:
            continue
        try:
            if (s.family in (socket.AF_INET, socket.AF_INET6) and
                    s.getpeername()[1] == port):
                s.shutdown(socket.SHUT_RDWR)
        except OSError:
            pass
        finally:
            s.close()


def connect(debugger, little_endian):
    run(debugger, f'settings set target.default-arch {TRIPLE[little_endian]}')
    run(debugger, f'gdb-remote {gdbstub}')
    target = debugger.GetSelectedTarget()
    if cpu_little_endian(target) != little_endian:
        return reconnect(debugger, not little_endian)
    run(debugger, f'target stop-hook add -P {__name__}.EndiannessStopHook')
    run(debugger, f'command source -s true {INIT_FILE[little_endian]}')


def reconnect(debugger, little_endian):
    endian = 'little' if little_endian else 'big'
    print(f'cpu switched to {endian}-endian, reconnecting to {gdbstub}')
    drop_connection(int(gdbstub.rsplit(':', 1)[1]))
    debugger.DeleteTarget(debugger.GetSelectedTarget())
    connect(debugger, little_endian)


class EndiannessStopHook:
    def __init__(self, target, extra_args, internal_dict):
        self.target = target

    def handle_stop(self, exe_ctx, stream):
        cpu_le = cpu_little_endian(self.target)
        if cpu_le != target_little_endian(self.target):
            reconnect(self.target.GetDebugger(), cpu_le)
        return True


def ppc64_connect(debugger, command, exe_ctx, result, internal_dict):
    """ppc64-connect host:port - connect to QEMU gdbstub"""
    global gdbstub
    gdbstub = command.strip() or 'localhost:1234'
    connect(debugger, False)


def __lldb_init_module(debugger, internal_dict):
    debugger.HandleCommand(
        f'command script add -o -f {__name__}.ppc64_connect ppc64-connect')
