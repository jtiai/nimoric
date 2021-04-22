import sequtils
import datatypes
import memory
import strutils

proc connectMemory*(bus: BusRef, mem: MemoryRef) = 
    bus.mem.add(mem)

proc firstMem(bus: BusRef, memaddr: uint16): MemoryRef =
    let f = bus.mem.filter(proc(x: MemoryRef): bool = memaddr in x.startAddr .. x.endAddr)
    result = f[0]

proc write*(bus: BusRef, memaddr: uint16, val: uint8) =
    let mem = bus.firstMem(memaddr)
    mem[memaddr] = val

proc read*(bus: BusRef, memaddr: uint16): uint8 =
    let mem = bus.firstMem(memaddr)
    result = mem[memaddr]

proc load*(bus: BusRef, memaddr: uint16, fname: string) =
    let mem = bus.firstMem(memaddr)
    let f = open(fname)
    let fsize = f.getFileSize()
    discard f.readBytes(mem.data, memaddr - mem.startAddr, fsize)
