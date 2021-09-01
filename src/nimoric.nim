import sequtils
import strformat
import fusion/btreetables
import sdl2/sdl
import sdl2/sdl_ttf as ttf
import datatypes
import cpu6502
import bus
import memory
import ula
import via6522

const
  windowTitle = "Nimoric"
  screenWidth = 1024
  screenHeight = 768
  windowFlags = 0
  renderFlags = sdl.RendererAccelerated or sdl.RendererPresentVsync
  fpsLimit = 60

type
  Oric = ref object
    window*: sdl.Window
    renderer*: sdl.Renderer
    texture*: sdl.Texture
    rect*: sdl.Rect
    font*: ttf.Font
    txtColor*: sdl.Color
    txtHiliteColor*: sdl.Color
    bus*: Bus
    cpu*: Cpu
    ula*: ULA
    via*: VIA6522
    disassembly*: Table[uint16, string]
    disasmKeys: seq[uint16]
    memory*: Memory
    ticks: uint64  # ticks counter
    freq: uint64 # counter frequency
    running: bool

proc init(oric: Oric): bool =
  if sdl.init(sdl.InitVideo or sdl.InitTimer) != 0:
    echo "ERROR: Can't initialize SDL: ", sdl.getError()
    return false

  if ttf.init() != 0:
    echo "ERROR: Can't initialize TTF: ", ttf.getError()

  oric.window = sdl.createWindow(
    windowTitle,
    sdl.WindowPosUndefined,
    sdl.WindowPosUndefined,
    screenWidth,
    screenHeight,
    windowFlags
  )

  if oric.window == nil:
    echo "ERROR: Can't create window: ", sdl.getError()
    return false

  oric.renderer = sdl.createRenderer(oric.window, -1, renderFlags)
  if oric.renderer == nil:
    echo "ERROR: Can't create renderer: ", sdl.getError()

  oric.font = ttf.openFont("fnt/debug.ttf", 14)
  if oric.font == nil:
    echo "ERROR: Can't load font: ", ttf.getError()

  oric.txtColor = sdl.Color(r: 0xFF, g: 0xFF, b: 0xFF)
  oric.txtHiliteColor = sdl.Color(r: 0x00, g: 0x00, b: 0xA0)
  oric.texture = sdl.createTexture(oric.renderer, sdl.PixelFormat_RGB888, sdl.TextureAccessStreaming, ula.width.cint, ula.height.cint)
  oric.rect = sdl.Rect(x: 0, y: 0, w: ula.width.int, h: ula.height.int)
  oric.freq = sdl.getPerformanceFrequency()

  oric.ula = newULA()
  oric.via = new6522(0x0200'u16)
  oric.memory = newMemory(0x0000'u16, 0xFFFF'u16)
  oric.bus = newBus()
  oric.cpu = newCPU()

  oric.bus.addDevice(oric.memory)
  oric.bus.addDevice(oric.ula)
  oric.bus.loadFile(0xC000'u16, "roms/basic11b.rom")

  oric.bus.cpu = oric.cpu
  oric.cpu.bus = oric.bus

  oric.via.init()
  oric.cpu.reset()

  oric.disassembly = oric.cpu.disassemble(0x0000'u16, 0xFFFF'u16)

  #oric.disasmKeys = newSeq[uint16]()
  oric.disasmKeys = toSeq(oric.disassembly.keys())
  oric.running = true

  echo "SDL initialized successfully"
  return true

proc exit(oric: Oric) =
  oric.renderer.destroyRenderer()
  oric.window.destroyWindow()
  ttf.quit()
  sdl.quit()
  echo "SDL shutdown completed"

var
  oric = Oric(window: nil, renderer: nil)
  done = false

proc render(renderer: sdl.Renderer, surface: sdl.Surface, x: int, y: int): bool =
  result = true
  var rect = sdl.Rect(x: x, y: y, w: surface.w, h: surface.h)
  var texture = sdl.createTextureFromSurface(renderer, surface)
  if texture == nil:
    return false
  if renderer.renderCopy(texture, nil, rect.addr) == 0:
    result = false
  destroyTexture(texture)

proc renderDebug(oric: Oric, x: int, y: int) =
  var disasm: seq[sdl.Surface] = newSeq[sdl.Surface]()
  let pcIdx = oric.disasmKeys.find(oric.cpu.pc)
  let finalKeys = oric.disasmKeys[pcIdx - 11 .. pcIdx + 11]
  var y = y
  for k in finalKeys:
    var s: sdl.Surface
    if k == oric.cpu.pc:
      s = oric.font.renderUTF8_Shaded(oric.disassembly[k], oric.txtColor, oric.txtHiliteColor)
    else:
      s = oric.font.renderUTF8_Solid(oric.disassembly[k], oric.txtColor)
    disasm.add(s)
    discard oric.renderer.render(s, x, y)
    sdl.freeSurface(s)
    y = y + s.h

proc renderCPUState(oric: Oric, x: int, y: int) =
  var fstr = ""
  for f in CPUFlag:
    if f in oric.cpu.flags:
      fstr &= $f & " "
    else:
      fstr &= "  "

  let data: seq[string] = @[
    fmt"a:      {oric.cpu.a:02X}",
    fmt"y:      {oric.cpu.y:02X}",
    fmt"x:      {oric.cpu.x:02X}",
    fmt"sp:     {oric.cpu.sp:02X}",
    fmt"pc:     {oric.cpu.pc:04X}",
    fmt"flags:  {fstr}"
  ]

  var y = y
  for str in data:
    var s: sdl.Surface
    s = oric.font.renderUTF8_Solid(str, oric.txtColor)
    discard oric.renderer.render(s, x, y)
    y = y + s.h
    sdl.freeSurface(s)

if init(oric):
  oric.ticks = sdl.getPerformanceCounter()

  while not done:
    discard oric.renderer.setRenderDrawColor(0x00, 0x20, 0x00, 0xFF)

    # Clear screen with draw color
    if oric.renderer.renderClear() != 0:
      echo "Warning: Can't clear screen: ", sdl.getError()

    # Run one frame of emulation (PAL50)
    if oric.running:
      for tick in 0 .. 20000:
        oric.cpu.clock()
        oric.via.tick()
        if tick mod 64 == 0:
          oric.ula.renderScanline()

    # Handle input
    var e: sdl.Event
    while sdl.pollEvent(e.addr) != 0:
      if e.kind == sdl.Quit:
        done = true
      if e.kind == sdl.Keydown:
        if e.key.keysym.sym == sdl.K_space:
          oric.running = not oric.running
        if e.key.keysym.sym == sdl.K_s and not oric.running:
          oric.cpu.clock()
          while not oric.cpu.complete():
            oric.cpu.clock()

    renderDebug(oric, 650, 150)
    renderCPUState(oric, 650, 10)

    discard sdl.updateTexture(oric.texture, nil, oric.ula.frameBuffer.unsafeAddr, ula.width.int * sizeof(uint32))
    discard sdl.renderCopy(oric.renderer, oric.texture, nil, oric.rect.addr)
    oric.renderer.renderPresent()

    # FPS limit
    let spare = (1000 / fpsLimit).uint32  - 1000'u32 * ((sdl.getPerformanceCounter() - oric.ticks).float / oric.freq.float).uint32
    if spare > 0'u32:
      sdl.delay(spare)
    oric.ticks = sdl.getPerformanceCounter()

# Shutdown
exit(oric)
