import datatypes
import bus as systembus
import cpu6502
import memory
import fusion/btreetables
import nimgl/imgui, nimgl/imgui/[impl_opengl, impl_glfw]
import nimgl/[opengl, glfw]

proc main() = 
    var
        bus = new Bus
        cpu = new CPU
        ram = newMemory(0x0000'u16, 0xDFFF'u16) # 56 kB RAM
        rom = newMemory(0xE000'u16, 0xFFFF'u16, true)  # 8 kiB ROM

    # Connect RAM and ROM to bus
    bus.connectMemory(ram)
    bus.connectMemory(rom)

    # Link the system
    bus.cpu = cpu
    cpu.bus = bus


    ram[0x8000] = "A2 0A 8E 00 00 A2 03 8E 01 00 AC 00 00 A9 00 18 6D 01 00 88 D0 FA 8D 02 00 EA EA EA"
    
    # Reset vector
    rom[0xFFFC] = 0x00
    rom[0xFFFD] = 0x80

    cpu.reset()
    
    let disAsm = cpu.disassemble(0x0000, 0xFFFF)

    doAssert glfwInit()

    glfwWindowHint(GLFWContextVersionMajor, 3)
    glfwWindowHint(GLFWContextVersionMinor, 3)
    glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE) # Used for Mac
    glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
    glfwWindowHint(GLFWResizable, GLFW_FALSE)

    let w: GLFWWindow = glfwCreateWindow(1280, 720)
    if w == nil:
        quit(-1)

    w.makeContextCurrent()

    doAssert glInit()
    
    let context = igCreateContext()

    doAssert igGlfwInitForOpenGL(w, true)
    doAssert igOpenGL3Init()

    igStyleColorsCherry()
  
    var show_demo: bool = true
    var somefloat: float32 = 0.0f
    var counter: int32 = 0
    

    while not w.windowShouldClose:
        glfwPollEvents()

        igOpenGL3NewFrame()
        igGlfwNewFrame()
        igNewFrame()

        # Simple window
        igBegin("Disassembly")

        var cnt = 10
        for l in disAsm.valuesFrom(cpu.pc):
            if cnt == 0: break
            dec cnt
            igText(l)
        igEnd()
        # End simple window

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
