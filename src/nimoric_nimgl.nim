import math
import datatypes
import bus as systembus
import cpu6502
import fusion/btreetables
import nimgl/imgui, nimgl/imgui/[impl_opengl, impl_glfw]
import nimgl/[opengl, glfw]
import strformat
import std/enumutils
import memory

type Emulator = object
  cpu: CPURef
  bus: BusRef
  disAsm: Table[uint16, string]
  memoryWidth: range[1..16]
  followPC: bool

func renderDisasm(e: Emulator) =
  igBegin("6502 Disassembler")
  discard igCheckbox("Follow PC", cast[ptr bool](e.followPC.unsafeAddr))
  igSetWindowPos(ImVec2(x: 1280-250, y: 0), ImGuiCond.Always)
  igSetWindowSize(ImVec2(x: 250, y: 700), ImGuiCond.Always)
  discard igBeginChild("Disassembler", ImVec2(x: -1, y: -1), false,
      ImGuiWindowFlags.HorizontalScrollbar)

  for a, l in e.disAsm.pairs:
    discard igSelectable("", a == e.cpu.pc, ImGuiSelectableFlags.None, ImVec2(x: 0, y: 0))
    if a == e.cpu.pc and e.followPC:
      igSetScrollHereY(0.5)
    igSameLine()
    igText(l)
  igEndChild()
  igEnd()

proc renderMemory(e: Emulator) =
  igSetNextWindowSizeConstraints(ImVec2(x: 400, y:0), ImVec2(x: float.high, y: float.high))
  igBegin("Memory")
  igSetNextItemWidth(-1)
  discard igSliderInt("##", cast[ptr int32](e.memoryWidth.unsafe_addr), 1, 16, "%d")
  discard igBeginChild("Memory", ImVec2(x: -1, y: -1), false, ImGuiWindowFlags.HorizontalScrollbar)

  var clipper: ImGuiListClipper

  let lo = 0x0000'u16
  let hi = 0xFFFF'u16
  let totalAddresses = (hi - lo).int  # In theory there can be gaps...
  let linesToDraw = ceil(totalAddresses / e.memoryWidth).int
  let lastLineAddress = linesToDraw * e.memoryWidth
  var lastLineItems = totalAddresses mod e.memoryWidth

  if lastLineItems == 0:
    lastLineItems = e.memoryWidth.int

  begin(clipper.addr, linesToDraw.int32)

  while step(clipper.addr):
    for offset in clipper.displayStart ..< clipper.displayEnd:
      let address = offset * e.memoryWidth

      # TODO: implement blocks display here

      var itemCount = e.memoryWidth.int
      if address == lastLineAddress:
        itemCount = lastLineItems

      igText(fmt"0x{int(address):>04x} |")
      for base in 0 ..< itemCount:
        igSameLine()
        igText(fmt"{e.bus.read((address + base).uint16):>02x}")

      for _ in itemCount ..< e.memoryWidth.int:
        igSameLine()
        igText("..")

      igSameLine()
      var text = "| "
      for base in 0 ..< itemCount:
          text &= fmt"{e.bus.read((address + base).uint16).chr}"
      for _ in itemCount ..< e.memoryWidth.int:
          text &= fmt" "
      igText(text)
  igEndChild()
  igEnd()

func renderCpuStatus(e: Emulator) =
  igBegin("CPU Status")
  igSetWindowSize(ImVec2(x: 250, y: 300), ImGuiCond.Always)
  igColumns(2)
  igText("A")
  igText("X")
  igText("Y")
  igText("PC")
  igText("SP")
  igText("Flags")
  igNextColumn()
  igText(fmt"{e.cpu.a:>02X}")
  igText(fmt"{e.cpu.x:>02X}")
  igText(fmt"{e.cpu.y:>02X}")
  igText(fmt"{e.cpu.pc:>04X}")
  igText(fmt"{e.cpu.sp:>02X}")
  # Flags
  var fstr = ""
  for f in CPUFlag:
    if f in e.cpu.flags:
      fstr &= $f & " "
    else:
      fstr &= "  "
  igText(fstr)

  igNextColumn()
  igSeparator()
  igText("Cycles")
  igNextColumn()
  igText($e.cpu.clockCount)
  igEnd()

var keys: Table[int32, bool]

proc keyProc(window: GLFWWindow, key: int32, scancode: int32,
            action: int32, mods: int32): void {.cdecl.} =
  if action == GLFWPress:
    if key == GLFWKey.Escape:
      window.setWindowShouldClose(true)
    else:
      keys[key] = true
  elif action == GLFWRelease:
    keys[key] = false

proc main() =
  var
    memory = newMemory(0x0000'u16, 0xFFFF'u16)
    bus = newBus()
    cpu = new CPU

  # Link the system
  bus.addDevice(memory)
  bus.cpu = cpu
  cpu.bus = bus


  #bus.loadHex(0x8000, "A2 0A 8E 00 00 A2 03 8E 01 00 AC 00 00 A9 00 18 6D 01 00 88 D0 FA 8D 02 00 EA EA EA")
  bus.loadFile(0xC000'u16, "roms/basic11b.rom")
  # Reset vector
  #bus.write(0xFFFC, 0x00)
  #bus.write(0xFFFD, 0x80)

  cpu.reset()

  let disAsm = cpu.disassemble(0x0000, 0xFFFF)

  var emulator = Emulator(
    cpu: cpu,
    bus: bus,
    disAsm: disAsm,
    followPC: true,
    memoryWidth: 8
    )

  doAssert glfwInit()

  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_FALSE)

  let w: GLFWWindow = glfwCreateWindow(1280, 720)
  if w == nil:
    quit(-1)

  for k in enumutils.items(GLFWKey):
    keys[cast[int32](k)] = false

  discard w.setKeyCallback(keyProc)

  w.makeContextCurrent()

  doAssert glInit()

  let context = igCreateContext()

  doAssert igGlfwInitForOpenGL(w, true)
  doAssert igOpenGL3Init()

  igStyleColorsCherry()

  while not w.windowShouldClose:
    glfwPollEvents()

    igOpenGL3NewFrame()
    igGlfwNewFrame()
    igNewFrame()

    if keys[GLFWKey.S]:
      keys[GLFWKey.S] = false
      var done = false
      while not done:
        emulator.cpu.clock()
        done = emulator.cpu.complete()

    renderDisasm(emulator)
    renderCpuStatus(emulator)
    renderMemory(emulator)

    igRender()

    glClearColor(0.45f, 0.55f, 0.60f, 1.00f)
    glClear(GL_COLOR_BUFFER_BIT)

    igOpenGL3RenderDrawData(igGetDrawData())

    w.swapBuffers()

  igOpenGL3Shutdown()
  igGlfwShutdown()
  context.igDestroyContext()

  w.destroyWindow()
  glfwTerminate()

main()
