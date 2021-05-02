import sdl2/sdl
import datatypes
import cpu6502
import bus
import memory
import ula

const
  windowTitle = "Nimoric"
  screenWidth = 640
  screenHeight = 480
  windowFlags = 0
  renderFlags = sdl.RendererAccelerated or sdl.RendererPresentVsync

type
  Oric = ref object
    window*: sdl.Window
    renderer*: sdl.Renderer
    bus*: Bus
    cpu*: Cpu
    ula*: ULA
    memory*: Memory

proc init(oric: Oric): bool =
  if sdl.init(sdl.InitVideo) != 0:
    echo "ERROR: Can't initialize SDL: ", sdl.getError()
    return false

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

  proc.renderer = sdl.createRenderer(app.window, -1, renderFlags)
  if oric.renderer == nil:
    echo "ERROR: Can't create renderer: ", sdl.getError()

  oric.ula = newULA()
  oric.memory = newMemory(0x0000'u16, 0xFFFF'u16)
  oric.bus = newBus()
  oric.cpu = new CPU()

  oric.bus.addDevice(oric.memory)
  oric.bus.addDevice(oric.ula)
  oric.bus.loadFile("roms/basic11b.rom")

  oric.bus.cpu = oric.cpu
  oric.cpu.bus = oric.bus

  oric.cpu.reset()

  echo "SDL initialized successfully"
  return true

proc exit(oric: Oric) =
  oric.renderer.destroyRenderer()
  oric.window.destroyWindow()
  sdl.quit()
  echo "SDL shutdown completed"

var
  oric = Oric(window: nil, renderer: nil)
  done = false

if init(app):

  while not done:
    discar app.renderer.setRenderDrawColor(0x00, 0x00, 0x00, 0xFF)

    # Clear screen with draw color
    if app.renderer.renderClear() != 0:
      echo "Warning: Can't clear screen: ", sdl.getError()

    # Run one frame of emulation (PAL50)
    for tick in 0 .. 20000:
      oric.cpu.clock()
      if tick % 60 == 0:
        ula.renderScanline()

    # Update renderer
    app.renderer.renderPresent()


# Shutdown
exit(app)
