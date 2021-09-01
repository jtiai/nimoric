import strformat
import datatypes
import device
import bus

const
  width* = 240'u16
  height* = 224'u16
  textAddr = 0xBB80'u16
  hiresAddr = 0xA000'u16
  charsetAddr = 0xB400'u16
  altCharsetAddr = 0xB800'u16

  black = 0x00000000'u32
  red = 0x00FF0000'u32
  green = 0x0000FF00'u32
  yellow = 0x00FFFF00'u32
  blue = 0x000000FF'u32
  magenta = 0x00FF00FF'u32
  cyan = 0x0000FFFF'u32
  white = 0x00FFFFFF'u32

type
  VideoMode = enum
    txtHires50
    txtLores50
    gfxHires50

  framebufferArray* = array[width * height, uint32]

  ULA* = ref object of Device
    gfxMode*: VideoMode
    scanLine*: uint16
    fgColor: uint32
    bgColor: uint32
    blink: bool
    frameBuffer*: framebufferArray

proc newULA*(): ULA =
  result = new ULA
  result.memoryMapped = false
  result.gfxMode = txtHires50
  result.scanLine = 0'u16
  result.fgColor = white
  result.bgColor = black

proc renderTextScanline(ula: ULA) =
  let ptrDisp = textAddr + (ula.scanLine.int / 8).uint16 * 40
  for pos in 0 .. 39:
    let c = ula.bus.read(ptrDisp)
    if c != 0x00'u8:
      echo fmt"{ptrDisp:04X} - {c:02X}"
    let ptrChar = charsetAddr + c * 8 + ula.scanLine mod 8'u16
    var bits = ula.bus.read(ptrChar)
    var fbPtr = ula.scanLine * width + pos.uint16 * 6'u16
    for _ in 0 .. 5:
      let byte = bits and 0x01'u8
      if byte == 0x01'u8:
        ula.frameBuffer[fbPtr] = ula.fgColor
      else:
        ula.frameBuffer[fbPtr] = ula.bgColor
      inc fbPtr
      bits = bits shr 1

proc renderScanline*(ula: ULA) =
  ula.fgColor = white
  ula.bgColor = black

  case ula.gfxMode:
  of txtHires50:
    ula.renderTextScanline()
  else:
    echo "Unknown video mode"

  inc ula.scanLine
  if ula.scanline == height:
    ula.scanline = 0
