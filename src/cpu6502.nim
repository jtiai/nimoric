{.experimental: "dotOperators".}
import with
import datatypes
import bus
import strutils
import fusion/btreetables

using
    cpu: CPURef

# Forward declaration of memory access types
proc amImp(cpu): uint8
proc amIMM(cpu): uint8
proc amZP0(cpu): uint8
proc amZPX(cpu): uint8
proc amZPY(cpu): uint8
proc amREL(cpu): uint8
proc amABS(cpu): uint8 
proc amABX(cpu): uint8
proc amABY(cpu): uint8
proc amIND(cpu): uint8
proc amIZX(cpu): uint8
proc amIZY(cpu): uint8

# Defined at the end of the file
var lookup: InstructionArray

template `.`(flags: CPUFlags, key: CPUFlag): bool = 
    flags.contains key

template `.=`(flags: CPUFlags, key: CPUFlag, val: bool) =
    if val: flags.incl key else: flags.excl key

# Return page (high 8 bits)
template page(a: uint16): uint16 = a and 0xFF00'u16

# Is value zero?
template isZero(v: uint16 | uint8): bool = (v.uint16 == 0x0000'u16)

# Is 8 bit value negative?
template isNeg(v: uint16 | uint8): bool = (v.uint16 == 0x0080'u16)

proc read*(cpu; memaddr: uint16): uint8 =
    cpu.bus.read(memaddr)

proc read16*(cpu; memaddr: uint16): uint16 =
    # Read 16 bit value in little endian mode.
    let lo: uint16 = cpu.read(memaddr).uint16
    let hi: uint16 = cpu.read(memaddr + 1).uint16
    result = (hi shl 8) or lo

proc write*(cpu; memaddr: uint16, val: uint8) =
    cpu.bus.write(memaddr, val)

proc write16*(cpu; memaddr: uint16, val: uint16) =
    # Write 16 bit value in little endian mode.
    cpu.bus.write(memaddr, (val and 0x00FF'u16).uint8)
    cpu.bus.write(memaddr + 1, ((val and 0xFF00'u16) shr 8).uint8)

proc reset*(cpu) =
    with cpu:
        addrAbs = 0xFFFC'u16
        pc = cpu.read16(addrAbs)

        a = 0x00'u8
        x = 0x00'u8
        y = 0x00'u8
        sp = 0xFD'u8

        flags = {U}

        addrAbs = 0x0000'u16
        addrRel = 0x0000'u16

        cycles = 0

template absSP(cpu): uint16 = 0x0100'u16 + cpu.sp.uint16

proc irq*(cpu) =
    with cpu:
        if not flags.I:
            cpu.write(cpu.absSP, ((pc shr 8) and 0x00FF'u16).uint8)
            dec sp
            cpu.write(cpu.absSP, (pc and 0x00FF'u16).uint8)
            dec sp

            flags.B = false
            flags.U = true
            flags.I = true
            cpu.write(cpu.absSP, cast[uint8](flags))
            dec sp

            addrAbs = 0xFFFE'u16
            pc = cpu.read16(addrAbs)

            cycles = 7

proc nmi*(cpu) =
    with cpu:
        cpu.write(cpu.absSP, ((pc shr 8) and 0x00FF'u16).uint8)
        dec sp
        cpu.write(cpu.absSP, (pc and 0x00FF'u16).uint8)
        dec sp

        flags.B = false
        flags.U = true
        flags.I = true
        cpu.write(cpu.absSP, cast[uint8](flags))
        dec sp

        addrAbs = 0xFFFE'u16
        pc = cpu.read16(addrAbs)

        cycles = 8

proc fetch(cpu): uint8 =
    # Fetch one byte from program counter location
    with cpu:
        if lookup[opcode].mode == amImp:
            fetched = cpu.read(addrAbs)
        result = fetched

proc clock*(cpu; runCycles: uint32) =
    # Perform one clock cycle of emulation
    with cpu:
        if cycles == 0:
            opcode = cpu.read(pc)
            flags.U = true

            let addCycle1 = lookup[opcode].mode(cpu)
            let addCycle2 = lookup[opcode].oper(cpu)

            cycles += (addCycle1 and addCycle2).int

            flags.U = true

proc disassemble*(cpu; start: uint16, stop: uint16): Table[uint16, string] =
    var
        memAddr: uint32 = start
        value: uint8 = 0x00'u8
        lo: uint8 = 0x00'u8
        hi: uint8 = 0x00'u8
        lineAddr: uint16 = 0x0000'u16
        disAsm = initTable[uint16, string]()

    while memAddr <= stop:
        lineAddr = memAddr.uint16

        var inst: string = "$" & memAddr.toHex() & ": "

        let opcode: uint8 = cpu.bus.read(memAddr.uint16)
        inc memAddr

        inst &= lookup[opcode].name & " "

        if lookup[opcode].mode == amIMP:
            inst &= " {IMP}"
        elif lookup[opcode].mode == amIMM:
            value = cpu.bus.read(memAddr.uint16)
            inc memAddr
            inst &= "#$" & value.toHex() & " {IMM}"
        elif lookup[opcode].mode == amZP0:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = 0x00'u8
            inst &= "$" & lo.toHex() & " {ZP0}"
        elif lookup[opcode].mode == amZPX:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = 0x00'u8
            inst &= "$" & lo.toHex() & ", X {ZPX}"
        elif lookup[opcode].mode == amZPY:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = 0x00'u8
            inst &= "$" & lo.toHex() & ", Y {ZPY}"
        elif lookup[opcode].mode == amIZX:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = 0x00'u8
            inst &= "($" & lo.toHex() & ", X) {IZX}"
        elif lookup[opcode].mode == amIZY:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = 0x00'u8
            inst &= "($" & lo.toHex() & ", Y) {IZY}"
        elif lookup[opcode].mode == amABS:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = cpu.bus.read(memAddr.uint16)
            inc memAddr
            inst &= "$" & (hi.uint16 shl 8 or lo.uint16).toHex() & " {ABS}"
        elif lookup[opcode].mode == amABX:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = cpu.bus.read(memAddr.uint16)
            inc memAddr
            inst &= "$" & (hi.uint16 shl 8 or lo.uint16).toHex() & ", X {ABX}"
        elif lookup[opcode].mode == amABY:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = cpu.bus.read(memAddr.uint16)
            inc memAddr
            inst &= "$" & (hi.uint16 shl 8 or lo.uint16).toHex() & ", Y {ABY}"
        elif lookup[opcode].mode == amIND:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = cpu.bus.read(memAddr.uint16)
            inc memAddr
            inst &= "$" & (hi.uint16 shl 8 or lo.uint16).toHex() & " {IND}"
        elif lookup[opcode].mode == amREL:
            value = cpu.bus.read(memAddr.uint16)
            inc memAddr
            inst &= "$" & value.toHex() & "[$" & (memAddr.uint16 + value).toHex() & "] {REL}"
        disAsm[lineAddr] = inst
    result = disAsm

proc amIMP(cpu): uint8 =
    # Address mode implied
    cpu.fetched = cpu.a
    result = 0'u8

proc amIMM(cpu): uint8 =
    # Address mode immediate
    with cpu:
        addrAbs = pc
        inc pc
    result = 0'u8

proc amZP0(cpu): uint8 =
    # Address mode zero page
    with cpu:
        addrAbs = cpu.read(pc).uint16
        inc pc
        addrAbs = addrAbs or 0x00FF'u16
    result = 0'u8

proc amZPX(cpu): uint8 =
    # Address mode zero page with X offset
    with cpu:
        addrAbs = cpu.read(pc) + x
        inc pc
        addrAbs = addrAbs or 0x00FF'u16
    result = 0'u8

proc amZPY(cpu): uint8 =
    # Address mode zero page with Y offset
    with cpu:
        addrAbs = cpu.read(pc) + y
        inc pc
        addrAbs = addrAbs or 0x00FF'u16
    result = 0'u8

proc amREL(cpu): uint8 =
    # Address mode relative (exclusive to branch instructions)
    with cpu:
        addrRel = cpu.read(pc)
        inc pc
        if (addrRel and 0x0080'u16) != 0'u16:
           addrRel = addrRel or 0xFF00'u16
    result = 0'u8

proc amABS(cpu): uint8 =
    # Address mode absolute
    with cpu:
        addrAbs = cpu.read16(pc)
        pc += 2'u16
    result = 0'u8

proc amABX(cpu): uint8 =
    # Address mode absolute with X offset.
    # +1 cycle if page boundary crossed
    with cpu:
        let lo: uint16 = cpu.read(pc).uint16
        inc pc
        let hi: uint16 = cpu.read(pc).uint16
        inc pc
        addrAbs = (hi shl 8) or lo
        addrAbs += x
        if (addrAbs and 0xFF00'u16) != (hi shl 8):
            result = 1'u8
        else:
            result = 0'u8

proc amABY(cpu): uint8 =
    # Address mode absolute with X offset.
    # +1 cycle if page boundary crossed
    with cpu:
        let lo: uint16 = cpu.read(pc).uint16
        inc pc
        let hi: uint16 = cpu.read(pc).uint16
        inc pc
        addrAbs = (hi shl 8) or lo
        addrAbs += y
        if (addrAbs and 0xFF00'u16) != (hi shl 8):
            result = 1'u8
        else:
            result = 0'u8

proc amIND(cpu): uint8 =
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
            addrAbs = (cpu.read(ptrAddr and 0xFF00).uint16 shl 8) or cpu.read(ptrAddr)
        else:
            # Normal behaviour
            addrAbs = cpu.read16(ptrAddr)

    result = 0'u8

proc amIZX(cpu): uint8 = 
    # Address mode indirect X
    with cpu:
        let t = cpu.read(pc)
        inc pc

        let lo = cpu.read((t + x) and 0x00FF'u16)
        let hi = cpu.read((t + x + 1) and 0x00FF'u16)

        addrAbs = (hi shl 8) or lo

    result = 0'u8

proc amIZY(cpu): uint8 = 
    # Address mode indirect X
    with cpu:
        let t = cpu.read(pc).uint16
        inc pc

        let lo = cpu.read(t and 0x00FF'u16).uint16
        let hi = cpu.read((t + 1) and 0x00FF'u16).uint16

        addrAbs = (hi shl 8) or lo

        if (addrAbs and 0xFF00'u16) != (hi shl 8):
            result = 1'u8
        else:
            result = 0'u8

proc opADC(cpu): uint8 =
    with cpu:
        discard cpu.fetch()

        let tmp: uint16 = a + fetched + (if flags.C: 1'u16 else: 0'u16)
        
        flags.C = tmp > 0x00FF'u16
        flags.Z = (tmp and 0x00FF'u16) == 0'u16

        flags.V = (not ((a.uint16 xor fetched.uint16) and (a.uint16 xor tmp)) and 0x0080'u16).bool

        flags.N = (tmp and 0x0080'u16).bool

        a = (tmp and 0x00FF'u16).uint8

        result = 1

proc opSBC(cpu): uint8 =
    with cpu:
        discard cpu.fetch()

        let value: uint16 = fetched.uint16 xor 0x00FF'u16
        let tmp: uint16 = a.uint16 + value + (if flags.C: 1'u16 else: 0'u16)
        flags.C = (tmp and 0xFF00'u16).bool
        flags.Z = (tmp and 0xFF00'u16) == 0'u16
        flags.V = ((tmp xor a.uint16) and ((tmp xor value) and 0x0080'u16)).bool
        flags.N = (tmp and 0x0080'u16).bool
        a = (tmp and 0x00FF'u16).uint8
    result = 1'u8

proc opAND(cpu): uint8 =
    with cpu:
        discard cpu.fetch()
        a = a and fetched
        flags.Z = a == 0x00'u8
        flags.N = (a and 0x80'u8).bool
    result = 1'u8

proc opASL(cpu): uint8 =
    with cpu:
        discard cpu.fetch()
        let tmp: uint16 = fetched.uint16 shl 1
        flags.C = (tmp and 0xFF00'u16) > 0'u16
        flags.Z = (tmp and 0x00FF'u16) == 0x0000'u16
        flags.N = (tmp and 0x0080'u16).bool
        if lookup[opcode].mode == amImp:
            a = (tmp and 0x00FF'u16).uint8
        else:
            cpu.write(addrAbs, (tmp and 0x00FF'u16).uint8)
    result = 0'u8

proc opBCC(cpu): uint8 =
    with cpu:
        if not flags.C:
            inc cycles
            addrAbs = pc + addrRel

            if (addrAbs and 0xFF00'u16) != (pc and 0xFF00'u16):
                inc cycles

            pc = addrAbs
    result = 0'u8

proc opBCS(cpu): uint8 =
    with cpu:
        if flags.C:
            inc cycles
            addrAbs = pc + addrRel

            if (addrAbs and 0xFF00'u16) != (pc and 0xFF00'u16):
                inc cycles
            
            pc = addrAbs

    result = 0'u8

proc opBEQ(cpu): uint8 =
    with cpu:
        if flags.Z:
            inc cycles
            addrAbs = pc + addrRel

            if (addrAbs and 0xFF00'u16) != (pc and 0xFF00'u16):
                inc cycles

            pc = addrAbs
    result = 0'u8

proc opBIT(cpu): uint8 = 
    with cpu:
        discard cpu.fetch()
        let tmp: uint16 = (a and fetched).uint16
        flags.Z = (tmp and 0x00FF).uint8 == 0x00'u8
        flags.N = (fetched and (1'u8 shl 7)).bool
        flags.V = (fetched and (1'u8 shl 6)).bool
    result = 0'u8

proc opBMI(cpu): uint8 =
    with cpu:
        if flags.N:
            inc cycles
            addrAbs = pc + addrRel
            if (addrAbs and 0xFF00'u16) != (pc and 0xFF00'u16):
                inc cycles

            pc = addrAbs
    result = 0

proc opBNE(cpu): uint8 =
    with cpu:
        inc cycles
        addrAbs = pc + addrRel

        if (addrAbs and 0xFF00'u16) != (pc and 0xFF00'u16):
            inc cycles

        pc = addrAbs
    result = 0

proc opBPL(cpu): uint8 =
    with cpu:
        if not flags.N:
            inc cycles
            addrAbs = pc + addrRel
            if (addrAbs and 0xFF00'u16) != (pc and 0xFF00'u16):
                inc cycles
            
            pc = addrAbs
    
    result = 0

proc opBRK(cpu): uint8 =
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

proc opBVC(cpu): uint8 =
    with cpu:
        if not flags.V:
            inc cycles
            addrAbs = pc + addrRel
            if page(addrAbs) != page(pc):
                inc cycles
            pc = addrAbs
    result = 0

proc opBVS(cpu): uint8 =
    with cpu:
        if flags.V:
            inc cycles
            addrAbs = pc + addrRel
            if page(addrAbs) != page(pc):
                inc cycles
            pc = addrAbs
    result = 0

proc opCLC(cpu): uint8 =
    cpu.flags.C = false
    result = 0

proc opCLD(cpu): uint8 =
    cpu.flags.D = false
    result = 0

proc opCLI(cpu): uint8 =
    cpu.flags.I = false
    result = 0

proc opCLV(cpu): uint8 =
    cpu.flags.V = false
    result = 0

proc opCMP(cpu): uint8 =
    with cpu:
        discard cpu.fetch()
        let tmp: uint16 = a.uint16 - fetched.uint16
        flags.C = a > fetched
        flags.Z = (tmp and 0x00FF'u16) == 0x0000'u16
        flags.N = (tmp and 0x0080'u16).bool
    result = 1

proc opCPX(cpu): uint8 =
    with cpu:
        discard cpu.fetch()
        let tmp: uint16 = x.uint16 - fetched.uint16
        flags.C = x >= fetched
        flags.Z = (tmp and 0x00FF'u16) == 0x0000'u16
        flags.N = (tmp and 0x0080'u16).bool
    result = 0

proc opCPY(cpu): uint8 =
    with cpu:
        discard cpu.fetch()
        let tmp: uint16 = y.uint16 - fetched.uint16
        flags.C = y >= fetched
        flags.Z = (tmp and 0x00FF'u16) == 0x0000'u16
        flags.N = (tmp and 0x0080'u16).bool
    result = 0

proc opDEC(cpu): uint8 =
    with cpu:
        discard cpu.fetch()
        let tmp: uint16 = fetched.uint16 - 1'u16
        cpu.write(addr_abs, (tmp and 0x00FF).uint8)
        flags.Z = (tmp and 0x00FF'u16) == 0x0000'u16
        flags.B = (tmp and 0x0080'u16).bool
    result = 0

proc opDEX(cpu): uint8 =
    with cpu:
        dec x
        flags.Z = x == 0x00'u8
        flags.N = (x and 0x80'u8).bool
    result = 0

proc opDEY(cpu): uint8 =
    with cpu:
        dec y
        flags.Z = y == 0x00'u8
        flags.B = (y and 0x80'u8).bool
    result = 0

proc opEOR(cpu): uint8 =
    with cpu:
        discard cpu.fetch()
        a = a xor fetched
        flags.Z = a == 0x00'u8
        flags.N = (a and 0x80'u8).bool
    result = 1

proc opINC(cpu): uint8 =
    with cpu:
        discard cpu.fetch()
        let tmp: uint16 = fetched.uint16 + 1'u16
        cpu.write(addr_abs, (tmp and 0x00FF'u16).uint8)
        flags.Z = (tmp and 0x00FF'u16) == 0x0000
        flags.N = (tmp and 0x0080).bool
    result = 0

proc opINX(cpu): uint8 =
    with cpu:
        inc x
        flags.Z = x == 0x00'u8
        flags.N = (x and 0x80'u8).bool
    result = 0

proc opINY(cpu): uint8 =
    with cpu:
        inc y
        flags.Z = y == 0x00'u8
        flags.N = (y and 0x80'u8).bool
    result = 0

proc opJMP(cpu): uint8 =
    cpu.pc = cpu.addr_abs
    result = 0

proc opJSR(cpu): uint8 =
    with cpu:
        dec pc
        cpu.write((0x0100 + sp).uint16, ((pc shr 8) and 0x00FF'u16).uint8)
        dec sp
        cpu.write((0x0100 + sp).uint16, (pc and 0x00FF'u16).uint8)
        dec sp

        pc = addrAbs
    result = 0

proc opLDA(cpu): uint8 =
    with cpu:
        discard cpu.fetch()
        a = fetched
        flags.Z = a == 0x00'u8
        flags.N = (a and 0x80'u8).bool
    result = 1

proc opLDX(cpu): uint8 =
    with cpu:
        discard cpu.fetch()
        x = fetched
        flags.Z = x == 0x00'u8
        flags.N = (x and 0x80'u8).bool
    result = 1

proc opLDY(cpu): uint8 =
    with cpu:
        discard cpu.fetch()
        y = fetched
        flags.Z = y == 0x00'u8
        flags.N = (y and 0x80'u8).bool
    result = 1

proc opLSR(cpu): uint8 =
    with cpu:
        discard cpu.fetch()
        flags.C = (fetched.uint16 and 0x0001'u16).bool
        let tmp: uint16 = fetched.uint16 shr 1
        flags.Z = (tmp and 0x00FF'u16) == 0x0000'u16
        flags.N = (tmp and 0x0080'u16).bool
        if lookup[opcode].mode == amIMP:
            a = (tmp and 0x00FF).uint8
        else:
            cpu.write(addr_abs, (tmp and 0x00FF'u16).uint8)
    result = 0

proc opNOP(cpu): uint8 =
    # Not all NOPs are equal.

    case cpu.opcode:
    of 0x1C'u8, 0x3C'u8, 0x5C'u8, 0x7C'u8, 0xDC'u8, 0xFC'u8:
        result = 1
    else:
        result = 0

proc opORA(cpu): uint8 =
    with cpu:
        discard cpu.fetch()
        a = a or fetched
        flags.Z = a == 0x00'u8
        flags.N = (a and 0x80'u8).bool
    result = 1

proc opPHA(cpu): uint8 =
    with cpu:
        cpu.write((0x0100 + sp).uint16, a)
        dec sp
    result = 0

proc opPHP(cpu): uint8 =
    with cpu:
        cpu.write(0x0100'u16 + sp, cast[uint8](flags) or cast[uint8](CPUFlag.B) or cast[uint8](CPUFlag.U))
        flags.B = false
        flags.U = false
        dec sp
    result = 0

proc opPLA(cpu): uint8 = 
    with cpu:
        inc sp
        a = cpu.read(0x0100'u16 + sp)
        flags.Z = a == 0x00'u8
        flags.N = (a and 0x80'u8).bool
    result = 0

proc opPLP(cpu): uint8 =
    with cpu:
        inc sp
        flags = cast[CPUFlags](cpu.read((0x0100'u16 + sp).uint16))
        flags.U = true
    result = 0

proc opROL(cpu): uint8 =
    with cpu:
        discard cpu.fetch()
        let tmp: uint16 = (fetched.uint16 shl 1) and (if flags.C: 1'u16 else: 0'u16)
        flags.C = (tmp and 0xFF00'u16).bool
        flags.Z = (tmp and 0x00FF'u16) == 0x0000'u16
        flags.N = (tmp and 0x0080'u16).bool
        if lookup[opcode].mode == amIMP:
            a = (tmp and 0x00FF'u16).uint8
        else:
            cpu.write(addrAbs, (tmp and 0x00FF'u16).uint8)
    result = 0

proc opROR(cpu): uint8 =
    with cpu:
        discard cpu.fetch()
        let tmp: uint16 = (if flags.C: 1'u16 shl 7 else: 0'u16) or (fetched.uint16 shr 1)
        flags.C = (tmp and 0x0001'u16).bool
        flags.Z = (tmp and 0x00FF'u16) == 0x0000'u16
        flags.N = (tmp and 0x0080'u16).bool
        if lookup[opcode].mode == amIMP:
            a = (tmp and 0x00FF'u16).uint8
        else:
            cpu.write(addrAbs, (tmp and 0x00FF'u16).uint8)
    result = 0

proc opRTI(cpu): uint8 =
    with cpu:
        inc sp
        flags = cast[CPUFlags](cpu.read((0x0100 + sp).uint16))
        flags.B = not flags.B
        flags.U = not flags.U

        inc sp
        pc = cpu.read((0x0100 + sp).uint16)
        inc sp
        pc = pc or (cpu.read((0x0100 + sp).uint16).uint16 shl 8)
    result = 0

proc opRTS(cpu): uint8 =
    with cpu:
        inc sp
        pc = cpu.read((0x0100 + sp).uint16)
        inc sp
        pc = pc or (cpu.read((0x0100 + sp).uint16).uint16 shl 8)
        inc pc
    result = 0

proc opSEC(cpu): uint8 =
    cpu.flags.C = true
    result = 0

proc opSED(cpu): uint8 =
    cpu.flags.D = true
    result = 0

proc opSEI(cpu): uint8 =
    cpu.flags.I = true
    result = 0

proc opSTA(cpu): uint8 =
    cpu.write(cpu.addrAbs, cpu.a)
    result = 0

proc opSTX(cpu): uint8 =
    cpu.write(cpu.addrAbs, cpu.x)
    result = 0

proc opSTY(cpu): uint8 =
    cpu.write(cpu.addrAbs, cpu.y)
    result = 0

proc opTAX(cpu): uint8 =
    with cpu:
        x = a
        flags.Z = x == 0x00'u8
        flags.N = (x and 0x80'u8).bool
    result = 0

proc opTAY(cpu): uint8 =
    with cpu:
        y = a
        flags.Z = y == 0x00'u8
        flags.N = (y and 0x80'u8).bool
    result = 0

proc opTSX(cpu): uint8 =
    with cpu:
        x = sp
        flags.Z = x == 0x00'u8
        flags.N = (x and 0x80'u8).bool
    result = 0

proc opTXA(cpu): uint8 =
    with cpu:
        a = x
        flags.Z = isZero(a)
        flags.N = isNeg(a)
    result = 0

proc opTXS(cpu): uint8 =
    cpu.sp = cpu.x
    result = 0

proc opTYA(cpu): uint8 =
    with cpu:
        a = y
        flags.Z = isZero(a)
        flags.N = isNeg(a)
    result = 0

proc opXXX(cpu): uint8 =
    result = 0

# Instruction lookup table
template I(n: string, o: proc(cpu: CPURef): uint8, m: proc(cpu: CPURef): uint8, c: int): Instruction =
    Instruction(name: n, oper: o, mode: m, cycles: c)

lookup[0x00] = I( "BRK", opBRK, amIMM, 7 )
lookup[0x01] = I( "ORA", opORA, amIZX, 6 )
lookup[0x02] = I( "???", opXXX, amIMP, 2 )
lookup[0x03] = I( "???", opXXX, amIMP, 8 )
lookup[0x04] = I( "???", opNOP, amIMP, 3 )
lookup[0x05] = I( "ORA", opORA, amZP0, 3 )
lookup[0x06] = I( "ASL", opASL, amZP0, 5 )
lookup[0x07] = I( "???", opXXX, amIMP, 5 )
lookup[0x08] = I( "PHP", opPHP, amIMP, 3 )
lookup[0x09] = I( "ORA", opORA, amIMM, 2 )
lookup[0x0A] = I( "ASL", opASL, amIMP, 2 )
lookup[0x0B] = I( "???", opXXX, amIMP, 2 )
lookup[0x0C] = I( "???", opNOP, amIMP, 4 )
lookup[0x0D] = I( "ORA", opORA, amABS, 4 )
lookup[0x0E] = I( "ASL", opASL, amABS, 6 )
lookup[0x0F] = I( "???", opXXX, amIMP, 6 )

lookup[0x10] = I( "BPL", opBPL, amREL, 2 )
lookup[0x11] = I( "ORA", opORA, amIZY, 5 )
lookup[0x12] = I( "???", opXXX, amIMP, 2 )
lookup[0x13] = I( "???", opXXX, amIMP, 8 )
lookup[0x14] = I( "???", opNOP, amIMP, 4 )
lookup[0x15] = I( "ORA", opORA, amZPX, 4 )
lookup[0x16] = I( "ASL", opASL, amZPX, 6 )
lookup[0x17] = I( "???", opXXX, amIMP, 6 )
lookup[0x18] = I( "CLC", opCLC, amIMP, 2 )
lookup[0x19] = I( "ORA", opORA, amABY, 4 )
lookup[0x1A] = I( "???", opNOP, amIMP, 2 )
lookup[0x1B] = I( "???", opXXX, amIMP, 7 )
lookup[0x1C] = I( "???", opNOP, amIMP, 4 )
lookup[0x1D] = I( "ORA", opORA, amABX, 4 )
lookup[0x1E] = I( "ASL", opASL, amABX, 7 )
lookup[0x1F] = I( "???", opXXX, amIMP, 7 )

lookup[0x20] = I( "JSR", opJSR, amABS, 6 )
lookup[0x21] = I( "AND", opAND, amIZX, 6 )
lookup[0x22] = I( "???", opXXX, amIMP, 2 )
lookup[0x23] = I( "???", opXXX, amIMP, 8 )
lookup[0x24] = I( "BIT", opBIT, amZP0, 3 )
lookup[0x25] = I( "AND", opAND, amZP0, 3 )
lookup[0x26] = I( "ROL", opROL, amZP0, 5 )
lookup[0x27] = I( "???", opXXX, amIMP, 5 )
lookup[0x28] = I( "PLP", opPLP, amIMP, 4 )
lookup[0x29] = I( "AND", opAND, amIMM, 2 )
lookup[0x2A] = I( "ROL", opROL, amIMP, 2 )
lookup[0x2B] = I( "???", opXXX, amIMP, 2 )
lookup[0x2C] = I( "BIT", opBIT, amABS, 4 )
lookup[0x2D] = I( "AND", opAND, amABS, 4 )
lookup[0x2E] = I( "ROL", opROL, amABS, 6 )
lookup[0x2F] = I( "???", opXXX, amIMP, 6 )

lookup[0x30] = I( "BMI", opBMI, amREL, 2 )
lookup[0x31] = I( "AND", opAND, amIZY, 5 )
lookup[0x32] = I( "???", opXXX, amIMP, 2 )
lookup[0x33] = I( "???", opXXX, amIMP, 8 )
lookup[0x34] = I( "???", opNOP, amIMP, 4 )
lookup[0x35] = I( "AND", opAND, amZPX, 4 )
lookup[0x36] = I( "ROL", opROL, amZPX, 6 )
lookup[0x37] = I( "???", opXXX, amIMP, 6 )
lookup[0x38] = I( "SEC", opSEC, amIMP, 2 )
lookup[0x39] = I( "AND", opAND, amABY, 4 )
lookup[0x3A] = I( "???", opNOP, amIMP, 2 )
lookup[0x3B] = I( "???", opXXX, amIMP, 7 )
lookup[0x3C] = I( "???", opNOP, amIMP, 4 )
lookup[0x3D] = I( "AND", opAND, amABX, 4 )
lookup[0x3E] = I( "ROL", opROL, amABX, 7 )
lookup[0x3F] = I( "???", opXXX, amIMP, 7 )

lookup[0x40] = I( "RTI", opRTI, amIMP, 6 )
lookup[0x41] = I( "EOR", opEOR, amIZX, 6 )
lookup[0x42] = I( "???", opXXX, amIMP, 2 )
lookup[0x43] = I( "???", opXXX, amIMP, 8 )
lookup[0x44] = I( "???", opNOP, amIMP, 3 )
lookup[0x45] = I( "EOR", opEOR, amZP0, 3 )
lookup[0x46] = I( "LSR", opLSR, amZP0, 5 )
lookup[0x47] = I( "???", opXXX, amIMP, 5 )
lookup[0x48] = I( "PHA", opPHA, amIMP, 3 )
lookup[0x49] = I( "EOR", opEOR, amIMM, 2 )
lookup[0x4A] = I( "LSR", opLSR, amIMP, 2 )
lookup[0x4B] = I( "???", opXXX, amIMP, 2 )
lookup[0x4C] = I( "JMP", opJMP, amABS, 3 )
lookup[0x3D] = I( "EOR", opEOR, amABS, 4 )
lookup[0x4E] = I( "LSR", opLSR, amABS, 6 )
lookup[0x4F] = I( "???", opXXX, amIMP, 6 )

lookup[0x50] = I( "BVC", opBVC, amREL, 2 )
lookup[0x51] = I( "EOR", opEOR, amIZY, 5 )
lookup[0x52] = I( "???", opXXX, amIMP, 2 )
lookup[0x53] = I( "???", opXXX, amIMP, 8 )
lookup[0x54] = I( "???", opNOP, amIMP, 4 )
lookup[0x55] = I( "EOR", opEOR, amZPX, 4 )
lookup[0x56] = I( "LSR", opLSR, amZPX, 6 )
lookup[0x57] = I( "???", opXXX, amIMP, 6 )
lookup[0x58] = I( "CLI", opCLI, amIMP, 2 )
lookup[0x59] = I( "EOR", opEOR, amABY, 4 )
lookup[0x5A] = I( "???", opNOP, amIMP, 2 )
lookup[0x5B] = I( "???", opXXX, amIMP, 7 )
lookup[0x5C] = I( "???", opNOP, amIMP, 4 )
lookup[0x5D] = I( "EOR", opEOR, amABX, 4 )
lookup[0x5E] = I( "LSR", opLSR, amABX, 7 )
lookup[0x5F] = I( "???", opXXX, amIMP, 7 )

lookup[0x60] = I( "RTS", opRTS, amIMP, 6 )
lookup[0x61] = I( "ADC", opADC, amIZX, 6 )
lookup[0x62] = I( "???", opXXX, amIMP, 2 )
lookup[0x63] = I( "???", opXXX, amIMP, 8 )
lookup[0x64] = I( "???", opNOP, amIMP, 3 )
lookup[0x65] = I( "ADC", opADC, amZP0, 3 )
lookup[0x66] = I( "ROR", opROR, amZP0, 5 )
lookup[0x67] = I( "???", opXXX, amIMP, 5 )
lookup[0x68] = I( "PLA", opPLA, amIMP, 4 )
lookup[0x69] = I( "ADC", opADC, amIMM, 2 )
lookup[0x6A] = I( "ROR", opROR, amIMP, 2 )
lookup[0x6B] = I( "???", opXXX, amIMP, 2 )
lookup[0x6C] = I( "JMP", opJMP, amIND, 5 )
lookup[0x6D] = I( "ADC", opADC, amABS, 4 )
lookup[0x6E] = I( "ROR", opROR, amABS, 6 )
lookup[0x6F] = I( "???", opXXX, amIMP, 6 )

lookup[0x70] = I( "BVS", opBVS, amREL, 2 )
lookup[0x71] = I( "ADC", opADC, amIZY, 5 )
lookup[0x72] = I( "???", opXXX, amIMP, 2 )
lookup[0x73] = I( "???", opXXX, amIMP, 8 )
lookup[0x74] = I( "???", opNOP, amIMP, 4 )
lookup[0x75] = I( "ADC", opADC, amZPX, 4 )
lookup[0x76] = I( "ROR", opROR, amZPX, 6 )
lookup[0x77] = I( "???", opXXX, amIMP, 6 )
lookup[0x78] = I( "SEI", opSEI, amIMP, 2 )
lookup[0x79] = I( "ADC", opADC, amABY, 4 )
lookup[0x7A] = I( "???", opNOP, amIMP, 2 )
lookup[0x7B] = I( "???", opXXX, amIMP, 7 )
lookup[0x7C] = I( "???", opNOP, amIMP, 4 )
lookup[0x7D] = I( "ADC", opADC, amABX, 4 )
lookup[0x7E] = I( "ROR", opROR, amABX, 7 )
lookup[0x7F] = I( "???", opXXX, amIMP, 7 )

lookup[0x80] = I( "???", opNOP, amIMP, 2 )
lookup[0x81] = I( "STA", opSTA, amIZX, 6 )
lookup[0x82] = I( "???", opNOP, amIMP, 2 )
lookup[0x83] = I( "???", opXXX, amIMP, 6 )
lookup[0x84] = I( "STY", opSTY, amZP0, 3 )
lookup[0x85] = I( "STA", opSTA, amZP0, 3 )
lookup[0x86] = I( "STX", opSTX, amZP0, 3 )
lookup[0x87] = I( "???", opXXX, amIMP, 3 )
lookup[0x88] = I( "DEY", opDEY, amIMP, 2 )
lookup[0x89] = I( "???", opNOP, amIMP, 2 )
lookup[0x8A] = I( "TXA", opTXA, amIMP, 2 )
lookup[0x8B] = I( "???", opXXX, amIMP, 2 )
lookup[0x8C] = I( "STY", opSTY, amABS, 4 )
lookup[0x8D] = I( "STA", opSTA, amABS, 4 )
lookup[0x8E] = I( "STX", opSTX, amABS, 4 )
lookup[0x8F] = I( "???", opXXX, amIMP, 4 )

lookup[0x90] = I( "BCC", opBCC, amREL, 2 )
lookup[0x91] = I( "STA", opSTA, amIZY, 6 )
lookup[0x92] = I( "???", opXXX, amIMP, 2 )
lookup[0x93] = I( "???", opXXX, amIMP, 6 )
lookup[0x94] = I( "STY", opSTY, amZPX, 4 )
lookup[0x95] = I( "STA", opSTA, amZPX, 4 )
lookup[0x96] = I( "STX", opSTX, amZPY, 4 )
lookup[0x97] = I( "???", opXXX, amIMP, 4 )
lookup[0x98] = I( "TYA", opTYA, amIMP, 2 )
lookup[0x99] = I( "STA", opSTA, amABY, 5 )
lookup[0x9A] = I( "TXS", opTXS, amIMP, 2 )
lookup[0x9B] = I( "???", opXXX, amIMP, 5 )
lookup[0x9C] = I( "???", opNOP, amIMP, 5 )
lookup[0x9D] = I( "STA", opSTA, amABX, 5 )
lookup[0x9E] = I( "???", opXXX, amIMP, 5 )
lookup[0x9F] = I( "???", opXXX, amIMP, 5 )

lookup[0xA0] = I( "LDY", opLDY, amIMM, 2 )
lookup[0xA1] = I( "LDA", opLDA, amIZX, 6 )
lookup[0xA2] = I( "LDX", opLDX, amIMM, 2 )
lookup[0xA3] = I( "???", opXXX, amIMP, 6 )
lookup[0xA4] = I( "LDY", opLDY, amZP0, 3 )
lookup[0xA5] = I( "LDA", opLDA, amZP0, 3 )
lookup[0xA6] = I( "LDX", opLDX, amZP0, 3 )
lookup[0xA7] = I( "???", opXXX, amIMP, 3 )
lookup[0xA8] = I( "TAY", opTAY, amIMP, 2 )
lookup[0xA9] = I( "LDA", opLDA, amIMM, 2 )
lookup[0xAA] = I( "TAX", opTAX, amIMP, 2 )
lookup[0xAB] = I( "???", opXXX, amIMP, 2 )
lookup[0xAC] = I( "LDY", opLDY, amABS, 4 )
lookup[0xAD] = I( "LDA", opLDA, amABS, 4 )
lookup[0xAE] = I( "LDX", opLDX, amABS, 4 )
lookup[0xAF] = I( "???", opXXX, amIMP, 4 )

lookup[0xB0] = I( "BCS", opBCS, amREL, 2 )
lookup[0xB1] = I( "LDA", opLDA, amIZY, 5 )
lookup[0xB2] = I( "???", opXXX, amIMP, 2 )
lookup[0xB3] = I( "???", opXXX, amIMP, 5 )
lookup[0xB4] = I( "LDY", opLDY, amZPX, 4 )
lookup[0xB5] = I( "LDA", opLDA, amZPX, 4 )
lookup[0xB6] = I( "LDX", opLDX, amZPY, 4 )
lookup[0xB7] = I( "???", opXXX, amIMP, 4 )
lookup[0xB8] = I( "CLV", opCLV, amIMP, 2 )
lookup[0xB9] = I( "LDA", opLDA, amABY, 4 )
lookup[0xBA] = I( "TSX", opTSX, amIMP, 2 )
lookup[0xBB] = I( "???", opXXX, amIMP, 4 )
lookup[0xBC] = I( "LDY", opLDY, amABX, 4 )
lookup[0xBD] = I( "LDA", opLDA, amABX, 4 )
lookup[0xBE] = I( "LDX", opLDX, amABY, 4 )
lookup[0xBF] = I( "???", opXXX, amIMP, 4 )

lookup[0xC0] = I( "CPY", opCPY, amIMM, 2 )
lookup[0xC1] = I( "CMP", opCMP, amIZX, 6 )
lookup[0xC2] = I( "???", opNOP, amIMP, 2 )
lookup[0xC3] = I( "???", opXXX, amIMP, 8 )
lookup[0xC4] = I( "CPY", opCPY, amZP0, 3 )
lookup[0xC5] = I( "CMP", opCMP, amZP0, 3 )
lookup[0xC6] = I( "DEC", opDEC, amZP0, 5 )
lookup[0xC7] = I( "???", opXXX, amIMP, 5 )
lookup[0xC8] = I( "INY", opINY, amIMP, 2 )
lookup[0xC9] = I( "CMP", opCMP, amIMM, 2 )
lookup[0xCA] = I( "DEX", opDEX, amIMP, 2 )
lookup[0xCB] = I( "???", opXXX, amIMP, 2 )
lookup[0xCC] = I( "CPY", opCPY, amABS, 4 )
lookup[0xCD] = I( "CMP", opCMP, amABS, 4 )
lookup[0xCE] = I( "DEC", opDEC, amABS, 6 )
lookup[0xCF] = I( "???", opXXX, amIMP, 6 )

lookup[0xD0] = I( "BNE", opBNE, amREL, 2 )
lookup[0xD1] = I( "CMP", opCMP, amIZY, 5 )
lookup[0xD2] = I( "???", opXXX, amIMP, 2 )
lookup[0xD3] = I( "???", opXXX, amIMP, 8 )
lookup[0xD4] = I( "???", opNOP, amIMP, 4 )
lookup[0xD5] = I( "CMP", opCMP, amZPX, 4 )
lookup[0xD6] = I( "DEC", opDEC, amZPX, 6 )
lookup[0xD7] = I( "???", opXXX, amIMP, 6 )
lookup[0xD8] = I( "CLD", opCLD, amIMP, 2 )
lookup[0xD9] = I( "CMP", opCMP, amABY, 4 )
lookup[0xDA] = I( "NOP", opNOP, amIMP, 2 )
lookup[0xDB] = I( "???", opXXX, amIMP, 7 )
lookup[0xDC] = I( "???", opNOP, amIMP, 4 )
lookup[0xDD] = I( "CMP", opCMP, amABX, 4 )
lookup[0xDE] = I( "DEC", opDEC, amABX, 7 )
lookup[0xDF] = I( "???", opXXX, amIMP, 7 )

lookup[0xE0] = I( "CPX", opCPX, amIMM, 2 )
lookup[0xE1] = I( "SBC", opSBC, amIZX, 6 )
lookup[0xE2] = I( "???", opNOP, amIMP, 2 )
lookup[0xE3] = I( "???", opXXX, amIMP, 8 )
lookup[0xE4] = I( "CPX", opCPX, amZP0, 3 )
lookup[0xE5] = I( "SBC", opSBC, amZP0, 3 )
lookup[0xE6] = I( "INC", opINC, amZP0, 5 )
lookup[0xE7] = I( "???", opXXX, amIMP, 5 )
lookup[0xE8] = I( "INX", opINX, amIMP, 2 )
lookup[0xE9] = I( "SBC", opSBC, amIMM, 2 )
lookup[0xEA] = I( "NOP", opNOP, amIMP, 2 )
lookup[0xEB] = I( "???", opSBC, amIMP, 2 )
lookup[0xEC] = I( "CPX", opCPX, amABS, 4 )
lookup[0xED] = I( "SBC", opSBC, amABS, 4 )
lookup[0xEE] = I( "INC", opINC, amABS, 6 )
lookup[0xEF] = I( "???", opXXX, amIMP, 6 )

lookup[0xF0] = I( "BEQ", opBEQ, amREL, 2 )
lookup[0xF1] = I( "SBC", opSBC, amIZY, 5 )
lookup[0xF2] = I( "???", opXXX, amIMP, 2 )
lookup[0xF3] = I( "???", opXXX, amIMP, 8 )
lookup[0xF4] = I( "???", opNOP, amIMP, 4 )
lookup[0xF5] = I( "SBC", opSBC, amZPX, 4 )
lookup[0xF6] = I( "INC", opINC, amZPX, 6 )
lookup[0xF7] = I( "???", opXXX, amIMP, 6 )
lookup[0xF8] = I( "SED", opSED, amIMP, 2 )
lookup[0xF9] = I( "SBC", opSBC, amABY, 4 )
lookup[0xFA] = I( "NOP", opNOP, amIMP, 2 )
lookup[0xFB] = I( "???", opXXX, amIMP, 7 )
lookup[0xFC] = I( "???", opNOP, amIMP, 4 )
lookup[0xFD] = I( "SBC", opSBC, amABX, 4 )
lookup[0xFE] = I( "INC", opINC, amABX, 7 )
lookup[0xFF] = I( "???", opXXX, amIMP, 7 )
