{.experimental: "dotOperators".}
import with
import datatypes
import bus

using
    cpu: CPURef

# Forward declaration
proc amImp(cpu): uint8

# Defined at the end of the file
var lookup: InstructionArray

template `.`*(flags: CPUFlags, key: CPUFlag): bool = 
    flags.contains key

template `.=`*(flags: CPUFlags, key: CPUFlag, val: bool) =
    if val: flags.incl key else: flags.excl key

proc read*(cpu; memaddr: uint16): uint8 =
    cpu.bus.read(memaddr)

proc read16*(cpu; memaddr: uint16): uint16 =
    # Read 16 bit value in low endian mode.
    let lo: uint16 = cpu.read(memaddr).uint16
    let hi: uint16 = cpu.read(memaddr + 1).uint16
    result = (hi shl 8) or lo

proc write*(cpu; memaddr: uint16, val: uint8) =
    cpu.bus.write(memaddr, val)

proc reset*(cpu) =
    with cpu:
        addr_abs = 0xFFFC'u16
        pc = cpu.read16(addr_abs)

    cpu.flags = {U}

proc fetch(cpu): uint8 =
    # Fetch one byte from program counter location
    with cpu:
        if lookup[opcode].mode == amImp:
            fetched = cpu.read(addr_abs)
        result = fetched

proc clock*(cpu; runCycles: uint32) =
    # Perform one clock cycle of emulation
    with cpu:
        if cycles == 0:
            opcode = cpu.read(pc)

proc amImp(cpu): uint8 =
    # Address mode implied
    cpu.fetched = cpu.a
    result = 0'u8

proc amImm(cpu): uint8 =
    # Address mode immediate
    with cpu:
        addr_abs = pc
        inc pc
    result = 0'u8

proc amZp0(cpu): uint8 =
    # Address mode zero page
    with cpu:
        addr_abs = cpu.read(pc).uint16
        inc pc
        addr_abs = addr_abs or 0x00FF'u16
    result = 0'u8

proc amZpX(cpu): uint8 =
    # Address mode zero page with X offset
    with cpu:
        addr_abs = cpu.read(pc) + x
        inc pc
        addr_abs = addr_abs or 0x00FF'u16
    result = 0'u8

proc amZpY(cpu): uint8 =
    # Address mode zero page with Y offset
    with cpu:
        addr_abs = cpu.read(pc) + y
        inc pc
        addr_abs = addr_abs or 0x00FF'u16
    result = 0'u8

proc amRel(cpu): uint8 =
    # Address mode relative (exclusive to branch instructions)
    with cpu:
        addr_rel = cpu.read(pc)
        inc pc
        if (addr_rel and 0x0080'u16) != 0'u16:
           addr_rel = addr_rel or 0xFF00'u16
    result = 0'u8

proc amAbs(cpu): uint8 =
    # Address mode absolute
    with cpu:
        addr_abs = cpu.read16(pc)
        pc += 2'u16
    result = 0'u8

proc amAbX(cpu): uint8 =
    # Address mode absolute with X offset.
    # +1 cycle if page boundary crossed
    with cpu:
        let lo: uint16 = cpu.read(pc).uint16
        inc pc
        let hi: uint16 = cpu.read(pc).uint16
        inc pc
        addr_abs = (hi shl 8) or lo
        addr_abs += x
        if (addr_abs and 0xFF00'u16) != (hi shl 8):
            result = 1'u8
        else:
            result = 0'u8

proc amAbY(cpu): uint8 =
    # Address mode absolute with X offset.
    # +1 cycle if page boundary crossed
    with cpu:
        let lo: uint16 = cpu.read(pc).uint16
        inc pc
        let hi: uint16 = cpu.read(pc).uint16
        inc pc
        addr_abs = (hi shl 8) or lo
        addr_abs += y
        if (addr_abs and 0xFF00'u16) != (hi shl 8):
            result = 1'u8
        else:
            result = 0'u8

proc amInd(cpu): uint8 =
    # Address mode indirect
    # Note: hardware bug simulation needed.
    with cpu:
        let ptrLo: uint16 = cpu.read(pc).uint16
        inc pc
        let ptrHi: uint16 = cpu.read(pc).uint16
        inc pc
        let ptrAddr: uint16 = (ptrHi shl 8) or ptrLo

        if ptrLo == 0x00FF:
            # Simulate hardware bug
            addr_abs = (cpu.read(ptrAddr and 0xFF00).uint16 shl 8) or cpu.read(ptrAddr)
        else:
            # Normal behaviour
            addr_abs = cpu.read16(ptrAddr)

    result = 0'u8

proc amIZX(cpu): uint8 = 
    # Address mode indirect X
    with cpu:
        let t = cpu.read(pc)
        inc pc

        let lo = cpu.read((t + x) and 0x00FF'u16)
        let hi = cpu.read((t + x + 1) and 0x00FF'u16)

        addr_abs = (hi shl 8) or lo

    result = 0'u8

proc amIZY(cpu): uint8 = 
    # Address mode indirect X
    with cpu:
        let t = cpu.read(pc).uint16
        inc pc

        let lo = cpu.read(t and 0x00FF'u16).uint16
        let hi = cpu.read((t + 1) and 0x00FF'u16).uint16

        addr_abs = (hi shl 8) or lo

        if (addr_abs and 0xFF00'u16) != (hi shl 8):
            result = 1'u8
        else:
            result = 0'u8

proc opAdc(cpu): uint8 =
    with cpu:
        discard cpu.fetch()

        let tmp: uint16 = a + fetched + (if flags.C: 1'u16 else: 0'u16)
        
        flags.C = tmp > 0x00FF'u16
        flags.Z = (tmp and 0x00FF'u16) == 0'u16

        flags.V = bool(not ((a.uint16 xor fetched.uint16) and (a.uint16 xor tmp)) and 0x0080'u16)

        flags.N = bool(tmp and 0x0080'u16)

        a = (tmp and 0x00FF'u16).uint8

        result = 1

proc opSbc(cpu): uint8 =
    with cpu:
        discard cpu.fetch()

        let value: uint16 = fetched.uint16 xor 0x00FF'u16
        let tmp: uint16 = a.uint16 + value + (if flags.C: 1'u16 else: 0'u16)
        flags.C = tmp and 0xFF00'u16
        flags.Z = (tmp and 0xFF00'u16) == 0'u16
        flags.V = (tmp xor a.uint16) and ((tmp xor value) and 0x0080'u16)
        flags.N = tmp and 0x0080'u16
        a = (tmp and 0x00FF'u16).uint8
    result = 1'u8

proc opAnd(cpu): uint8 =
    with cpu:
        discard cpu.fetch()
        a = a and fetched
        flags.Z = a == 0x00'u8
        flags.N = a and 0x80'u8
    result = 1'u8

proc opAsl(cpu): uint8 =
    with cpu:
        discard cpu.fetch()
        let tmp: uint16 = fetched.uint16 shl 1
        flags.C = (tmp and 0xFF00'u16) > 0'u16
        flags.Z = (tmp and 0x00FF'u16) == 0x0000'u16
        flags.N = tmp and 0x0080'u16
        if lookup[opcode].mode == amImp:
            a = (temp and 0x00FF'u16).uint8
        else:
            cpu.write(addr_abs, (tmp and 0x00FF'u16).uint8)
    result = 0'u8

proc opBcc(cpu): uint8 =
    with cpu:
        if not flags.C:
            inc cycles
            addr_abs = pc + addr_rel

            if (addr_abs and 0xFF00'u16) != (pc and 0xFF00'u16):
                inc cycles

            pc = addr_abs
    result = 0'u8

proc opBcs(cpu): uint8 =
    with cpu:
        if flags.C:
            inc cycles
            addr_abs = pc + addr_rel

            if (addr_abs and 0xFF00'u16) != (pc and 0xFF00'u16):
                inc cycles
            
            pc = addr_abs

    result = 0'u8

proc opBrk(cpu): uint8 =
    with cpu:
        inc pc
        flags.I = true
        cpu.write(0x0100'u16 + sp, ((pc shr 8) and 0x00FF).uint8)
        dec sp
        cpu.write(0x0100'u16 + sp, (pc and 0x00FF).uint8)
        dec sp

        flags.B = true
        cpu.write(0x0100'u16 + sp, cast[uint8](flags))
        dec sp
        flags.B = false

        pc = cpu.read16(0xFFFE'u16)
    result = 0'u8

# Instruction lookup table
template I(n: string, o: proc(cpu: CPURef): uint8, m: proc(cpu: CPURef): uint8, c: int) =
    Instruction(name: n, oper: o, mode: m, cycles: cycles)

lookup[0] = I("BRK", opBrk, amImp, 7)
