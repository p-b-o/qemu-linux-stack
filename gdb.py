import gdb

def current_symbol():
    try:
        name = gdb.selected_frame().name
        if name is None:
            return ''
        else:
            return name()
    except:
            return ''

def current_binary():
    try:
        return gdb.selected_frame().find_sal().symtab.objfile.filename
    except:
        return ''

def current_function():
    try:
        return gdb.selected_frame().name()
    except:
        return ''

def current_callstack():
    res = []
    f = gdb.selected_frame()
    while f:
        name = f.name()
        res.append(name if name else hex(f.pc()))
        f = f.older()
    res.reverse()
    return res

def current_source():
    try:
        return gdb.selected_frame().find_sal().symtab.fullname()
    except:
        return ''

def current_line():
    try:
        return gdb.selected_frame().find_sal().line
    except:
        return ''

def current_x64_privilege_level():
    # returned value is a gdb.Value, which supports bitwise operation, but
    # rounds to another value, resulting in a wrong PL. So convert to int.
    cr0 = int(gdb.selected_frame().read_register('cr0'))
    protected_mode = cr0 & 0b1;
    if not protected_mode:
        return 'RealMode'
    cs = int(gdb.selected_frame().read_register('cs'))
    ring_level = cs & 0b11;
    return 'Ring' + str(ring_level)

def current_location():
    return current_source() + ':' + str(current_line())

def step_instruction_until_state_change(state_name, get_state, print_state=True):
    from_state = get_state()
    from_symbol = current_symbol()
    from_location = current_location()
    from_source = current_source()
    last_symbol = from_symbol
    last_location = from_location
    count = 0
    while True:
        gdb.execute('stepi')
        count += 1
        new_state = get_state()
        if new_state and new_state != from_state:
            if print_state:
                print('from_{}: {}'.format(state_name, from_state))
                print('to_{}: {}'.format(state_name, new_state))
                print('from: {} @ {}'.format(from_symbol, from_location))
                print('last: {} @ {}'.format(last_symbol, last_location))
                print('to: {} @ {}'.format(current_symbol(), current_location()))
                print('{} insn executed'.format(count))
            return count
        last_symbol = current_symbol()
        last_location = current_location()

# Single step until we reach a new object file
class next_binary(gdb.Command):
    def __init__(self):
        super(next_binary, self).__init__('next-binary', gdb.COMMAND_USER)

    def invoke(self, argument, fromtty):
        step_instruction_until_state_change('binary', current_binary)

# Single step until function change
class next_function(gdb.Command):
    def __init__(self):
        super(next_function, self).__init__('next-function', gdb.COMMAND_USER)

    def invoke(self, argument, fromtty):
        step_instruction_until_state_change('function', current_function)

# Single step until we reach a new source file
class next_source(gdb.Command):
    def __init__(self):
        super(next_source, self).__init__('next-source', gdb.COMMAND_USER)

    def invoke(self, argument, fromtty):
        step_instruction_until_state_change('source', current_source)

# Single step until privilege level change
class next_x64_privilege_level(gdb.Command):
    def __init__(self):
        super(next_x64_privilege_level, self).__init__('next-x64-privilege-level', gdb.COMMAND_USER)

    def invoke(self, argument, fromtty):
        step_instruction_until_state_change('PL', current_x64_privilege_level)

# Print current privilege level
class x64_privilege_level(gdb.Command):
    def __init__ (self):
        super (x64_privilege_level, self).__init__ ("x64-privilege-level", gdb.COMMAND_USER)

    def invoke (self, arg, from_tty):
        print(current_x64_privilege_level())

# Print callstack
class callstack(gdb.Command):
    def __init__ (self):
        super (callstack, self).__init__ ("callstack", gdb.COMMAND_USER)

    def invoke (self, arg, from_tty):
        print(current_callstack())

# Single step until callstack change
class next_callstack(gdb.Command):
    def __init__(self):
        super(next_callstack, self).__init__('next-callstack', gdb.COMMAND_USER)

    def invoke(self, argument, fromtty):
        step_instruction_until_state_change('callstack', current_callstack)

x64_privilege_level()
callstack()
next_x64_privilege_level()
next_binary()
next_callstack()
next_function()
next_source()
