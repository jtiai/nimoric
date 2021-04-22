import datatypes
import strutils
import parseutils

proc newMemory*(s: uint16, e: uint16, ro: bool = false): ref Memory =
    result = new Memory
    result.startAddr = s
    result.endAddr = e
    result.data = newSeq[uint8](e - s + 1)
    result.readOnly = ro

proc `[]`*(m: MemoryRef, a: uint16): uint8 =
    m.data[a - m.startAddr]

proc `[]=`*(m: MemoryRef, a: uint16, v: uint8) =
    m.data[a - m.startAddr] = v

# Accept hex string, space separated values
proc `[]=`*(m: MemoryRef, a: uint16, v: string) =
    var memAddr = a - m.startAddr
    var tmp: uint8

    for hex in split(v):
        discard parseHex(hex, tmp)
        m[memAddr] = tmp
        inc memAddr

proc debug*(x: ref Memory): string =
    toHex(x.startAddr) & " - " & toHex(x.endAddr)
