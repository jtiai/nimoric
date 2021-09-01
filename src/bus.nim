# Bus is heart of Oric emulation.
#
# Bus handles device IO, memory IO and timing.

import parseutils
import sequtils
import streams
import strutils
import datatypes
import device

func newBus*(): Bus =
  result = new Bus
  result.devices = newSeq[Device]()

func addDevice*(bus: Bus, dev: Device) =
  bus.devices.add(dev)
  dev.bus = bus

proc read*(bus: Bus, memAddr: uint16): uint8 =
  for dev in bus.devices:
    if dev.memoryMapped and (memAddr in dev.startAddress .. dev.endAddress):
      result = dev.read(memAddr)

proc write*(bus: Bus, memAddr: uint16, val: uint8) =
  for dev in bus.devices:
    if dev.memoryMapped and (memAddr in dev.startAddress .. dev.endAddress):
      dev.write(memAddr, val)

proc loadFile*(bus: Bus, memAddr: uint16, fname: string) =
  # NOTE: Can actually owerflow.
  let s = newFileStream(fname, fmRead)
  var a = memAddr
  while not s.atEnd:
    bus.write(a, s.readUInt8)
    inc a

proc loadHex*(bus: Bus, memAddr: uint16, data: string) =
  var tmp: uint8
  var a = memAddr
  for hex in split(data):
    discard parseHex(hex, tmp)
    bus.write(a, tmp)
    inc a
