type
  Bus* = ref object
    cpu*: CPU
    devices*: seq[Device]

  Device* = ref object of RootObj
    name*: string
    bus*: Bus
    memoryMapped*: bool
    startAddress*: uint16
    endAddress*: uint16

  CPUFlag* {.size: sizeof(cuchar).} = enum
    C  # Carry
    Z  # Zero
    I  # Interrupt disable
    D  # Decimal mode
    B  # Break
    U  # Unused
    V  # Overflow
    N  # Negative

  CPUFlags* = set[CPUFlag]

  CPU* = ref object
    a*: uint8
    x*: uint8
    y*: uint8
    flags*: CPUFlags
    pc*: uint16
    sp*: uint8  # Relative address to 0x100

    bus*: Bus

    addrAbs*: uint16  # Absolute address fetched
    addrRel*: uint16  # Relative address fetched
    fetched*: uint8  # Input value for ALU
    opcode*: uint8  # Instruction byte
    cycles*: int  # Cycles remaining
    clockCount*: int  # Total clock count emulation has been running

  Instruction* = object
    name*: string
    cycles*: uint8
    oper*: proc(cpu: CPU): uint8    # operation
    mode*: proc(cpu: CPU): uint8    # addressing mode

  InstructionArray* = array[256, Instruction]
