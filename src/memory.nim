import strformat
import datatypes
import device

type
  Memory* = ref object of Device
    mem: seq[uint8]

proc newMemory*(s: uint16, e: uint16): Memory =
  result = new Memory
  result.memoryMapped = true
  result.startAddress = s
  result.endAddress = e
  result.mem = newSeq[uint8](e.uint32 - s.uint32 + 1'u32)

method read*(dev: Memory, memAddr: uint16): uint8 =
  dev.mem[memAddr - dev.startAddress]

method write*(dev: Memory, memAddr: uint16, val: uint8) =
  if memAddr in 0xBB80'u16 .. 0xBFDF'u16:
    echo fmt"Writing {val:02X} into {memAddr:04X}"
  try:
    dev.mem[memAddr - dev.startAddress] = val
  except IndexDefect:
    echo fmt"Trying to write {val:>02x} to address {memAddr:>04x}"


