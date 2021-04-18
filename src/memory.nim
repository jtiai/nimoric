import datatypes

proc newMemory*(s: uint16, e: uint16, ro: bool = false): ref Memory =
    result = new Memory
    result.startAddr = s
    result.endAddr = e
    result.data = newSeq[uint8](e - s)
    result.readOnly = ro

proc `[]`*(m: MemoryRef, a: uint16): uint8 =
    m.data[a - m.startAddr]

proc `[]=`*(m: MemoryRef, a: uint16, v: uint8) =
    m.data[a - m.startAddr] = v
