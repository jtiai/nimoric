import datatypes
import device

const
  width = 240'u16
  height = 224'u16
  textAddr = 0xBBA8'u16
  hiresAddr = 0xA000'u16
  charsetAddr = 0xB400'u16
  altCharsetAddr = 0xB800'u16

type
  VideoMode = enum
    txtHires50
    txtLores50
    gfxHires50

  OricColor = enum
    black
    red
    green
    yellow
    blue
    magenta
    cyan
    white

  ULA = ref object of Device
    gfxMode*: VideoMode
    scanLine*: uint16
    fgColor: OricColor
    bgColor: OricColor
    blink: bool
    screenBuffer*: array[width * height, uint8]

proc newULA(): ULA =
  result = new ULA
  result.memoryMapped = false
  result.gfxMode = txtHires50
  result.scanLine = 0'u16
  result.fgColor = white
  result.bgColor = black

proc renderTextScanline(ula: ULA) =
  let ptrDisp = textAddr + (ula.scanLine.int / 8).uint16 * 40'u16
  for pos in 0 .. 39:
    let c = ula.bus.read(ptrDisp)
    let ptrChar = charsetAddr + c * 8 + ula.scanLine mod 8'u16
    var bits = ula.bus.read(ptrChar)
    array[ula.scanLine * width + pos * 8]

proc renderScanline(ula: ULA) =
  ula.fgColor = white
  ula.bgColor = black

  case ula.gfxMode:
  of txtHires50:
    ula.renderTextScanline()

  inc ula.scanLine
  if ula.scanline == height:
    ula.scanline = 0
