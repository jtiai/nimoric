import datatypes
import bus as systembus
import cpu6502
import memory

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
