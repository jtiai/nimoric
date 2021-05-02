{.experimental: "dotOperators".}
import with
import datatypes
import bus
import strformat
import fusion/btreetables

using
    cpu: CPU

# Forward declaration of memory access types
proc amIMP(cpu): uint8
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

# Dot access for CPU flags
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
    ## Read 8 bit value from bus
    cpu.bus.read(memaddr)

proc read16*(cpu; memaddr: uint16): uint16 =
    ## Read 16 bit value in little endian mode from bus
    let lo: uint16 = cpu.read(memaddr).uint16
    let hi: uint16 = cpu.read(memaddr + 1).uint16
    result = (hi shl 8) or lo

proc write*(cpu; memaddr: uint16, val: uint8) =
    ## Write 8 bit value to bus
    cpu.bus.write(memaddr, val)

proc write16*(cpu; memaddr: uint16, val: uint16) =
    ## Write 16 bit value in little endian mode to bus
    cpu.bus.write(memaddr, (val and 0x00FF'u16).uint8)
    cpu.bus.write(memaddr + 1, ((val and 0xFF00'u16) shr 8).uint8)

proc reset*(cpu) =
    ## Reset CPU to initial state.
    ## Reset vector address is read from address 0xFFFC
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
    ## IRQ handler
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
    ## NMI Handler
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
    ## Fetch one byte from program counter location
    with cpu:
        if lookup[opcode].mode != amImp:
            fetched = cpu.read(addrAbs)
        result = fetched

proc clock*(cpu) =
    ## Perform one clock cycle of emulation
    with cpu:
        if cycles == 0:
            opcode = cpu.read(pc)
            flags.U = true
            inc pc

            cycles = lookup[opcode].cycles.int

            let addCycle1 = lookup[opcode].mode(cpu)
            let addCycle2 = lookup[opcode].oper(cpu)

            cycles += (addCycle1 and addCycle2).int

            flags.U = true

        inc clockCount
        dec cycles

func complete*(cpu;): bool =
    ## Is one curret op complete?
    cpu.cycles == 0

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

        var inst: string = fmt"${memAddr:>04X}: "

        let opcode: uint8 = cpu.bus.read(memAddr.uint16)
        inc memAddr

        inst &= lookup[opcode].name & " "

        if lookup[opcode].mode == amIMP:
            inst &= " {IMP}"
        elif lookup[opcode].mode == amIMM:
            value = cpu.bus.read(memAddr.uint16)
            inc memAddr
            inst &= fmt"#${value:>02X} {{IMM}}"
        elif lookup[opcode].mode == amZP0:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = 0x00'u8
            inst &= fmt"${lo:>02X} {{ZP0}}"
        elif lookup[opcode].mode == amZPX:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = 0x00'u8
            inst &= fmt"${lo:>02X}, X {{ZPX}}"
        elif lookup[opcode].mode == amZPY:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = 0x00'u8
            inst &= fmt"${lo:>02X}, Y {{ZPY}}"
        elif lookup[opcode].mode == amIZX:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = 0x00'u8
            inst &= fmt"(${lo:>02X}, X) {{IZX}}"
        elif lookup[opcode].mode == amIZY:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = 0x00'u8
            inst &= fmt"(${lo:>02X}, Y) {{IZY}}"
        elif lookup[opcode].mode == amABS:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = cpu.bus.read(memAddr.uint16)
            inc memAddr
            inst &= fmt"${(hi.uint16 shl 8 or lo.uint16):>04X} {{ABS}}"
        elif lookup[opcode].mode == amABX:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = cpu.bus.read(memAddr.uint16)
            inc memAddr
            inst &= fmt"${(hi.uint16 shl 8 or lo.uint16):>04X}, X {{ABX}}"
        elif lookup[opcode].mode == amABY:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = cpu.bus.read(memAddr.uint16)
            inc memAddr
            inst &= fmt"${(hi.uint16 shl 8 or lo.uint16):>04X}, Y {{ABY}}"
        elif lookup[opcode].mode == amIND:
            lo = cpu.bus.read(memAddr.uint16)
            inc memAddr
            hi = cpu.bus.read(memAddr.uint16)
            inc memAddr
            inst &= fmt"${(hi.uint16 shl 8 or lo.uint16):>04X} {{IND}}"
        elif lookup[opcode].mode == amREL:
            value = cpu.bus.read(memAddr.uint16)
            inc memAddr
            inst &= fmt"${value:>02x} [${(memAddr.uint16 + value):>04X}] {{REL}}"
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
        if lookup[opcode].mode == amIMP:
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
        if not flags.Z:
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

# Include opcode lookup table
include "opcode_lookup.nim"
