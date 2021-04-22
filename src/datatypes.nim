type
    Memory* = object
        name*: string
        startAddr*: uint16
        endAddr*: uint16
        readOnly*: bool
        data*: seq[uint8]

    MemoryRef* = ref Memory

    Bus* = object
        cpu*: ref CPU
        mem*: seq[MemoryRef]

    BusRef* = ref Bus

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

    CPU* = object
        a*: uint8
        x*: uint8
        y*: uint8
        flags*: CPUFlags
        pc*: uint16
        sp*: uint8  # Relative address to 0x100

        bus*: BusRef

        addrAbs*: uint16  # Absolute address fetched
        addrRel*: uint16  # Relative address fetched
        fetched*: uint8  # Input value for ALU
        opcode*: uint8  # Instruction byte
        cycles*: int  # Cycles remaining
        clock_count*: int  # Total clock count emulation has been running

    CPURef* = ref CPU

    Instruction* = object
        name*: string
        cycles*: uint8
        oper*: proc(cpu: CPURef): uint8    # operation
        mode*: proc(cpu: CPURef): uint8    # addressing mode

    InstructionArray* = array[256, Instruction]

