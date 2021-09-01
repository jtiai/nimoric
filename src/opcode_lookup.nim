    # Instruction lookup table
    template I(n: string, o: proc(cpu: CPU): uint8, m: proc(cpu: CPU): uint8, c: int): Instruction =
        Instruction(name: n, oper: o, mode: m, cycles: c)

lookup[0x00] = I( "BRK", opBRK, amIMM, 7 )
lookup[0x01] = I( "ORA", opORA, amIZX, 6 )
lookup[0x02] = I( "???", opXXX, amIMP, 2 )
lookup[0x03] = I( "???", opXXX, amIMP, 8 )
lookup[0x04] = I( "???", opNOP, amIMP, 3 )
lookup[0x05] = I( "ORA", opORA, amZP0, 3 )
lookup[0x06] = I( "ASL", opASL, amZP0, 5 )
lookup[0x07] = I( "???", opXXX, amIMP, 5 )
lookup[0x08] = I( "PHP", opPHP, amIMP, 3 )
lookup[0x09] = I( "ORA", opORA, amIMM, 2 )
lookup[0x0A] = I( "ASL", opASL, amIMP, 2 )
lookup[0x0B] = I( "???", opXXX, amIMP, 2 )
lookup[0x0C] = I( "???", opNOP, amIMP, 4 )
lookup[0x0D] = I( "ORA", opORA, amABS, 4 )
lookup[0x0E] = I( "ASL", opASL, amABS, 6 )
lookup[0x0F] = I( "???", opXXX, amIMP, 6 )

lookup[0x10] = I( "BPL", opBPL, amREL, 2 )
lookup[0x11] = I( "ORA", opORA, amIZY, 5 )
lookup[0x12] = I( "???", opXXX, amIMP, 2 )
lookup[0x13] = I( "???", opXXX, amIMP, 8 )
lookup[0x14] = I( "???", opNOP, amIMP, 4 )
lookup[0x15] = I( "ORA", opORA, amZPX, 4 )
lookup[0x16] = I( "ASL", opASL, amZPX, 6 )
lookup[0x17] = I( "???", opXXX, amIMP, 6 )
lookup[0x18] = I( "CLC", opCLC, amIMP, 2 )
lookup[0x19] = I( "ORA", opORA, amABY, 4 )
lookup[0x1A] = I( "???", opNOP, amIMP, 2 )
lookup[0x1B] = I( "???", opXXX, amIMP, 7 )
lookup[0x1C] = I( "???", opNOP, amIMP, 4 )
lookup[0x1D] = I( "ORA", opORA, amABX, 4 )
lookup[0x1E] = I( "ASL", opASL, amABX, 7 )
lookup[0x1F] = I( "???", opXXX, amIMP, 7 )

lookup[0x20] = I( "JSR", opJSR, amABS, 6 )
lookup[0x21] = I( "AND", opAND, amIZX, 6 )
lookup[0x22] = I( "???", opXXX, amIMP, 2 )
lookup[0x23] = I( "???", opXXX, amIMP, 8 )
lookup[0x24] = I( "BIT", opBIT, amZP0, 3 )
lookup[0x25] = I( "AND", opAND, amZP0, 3 )
lookup[0x26] = I( "ROL", opROL, amZP0, 5 )
lookup[0x27] = I( "???", opXXX, amIMP, 5 )
lookup[0x28] = I( "PLP", opPLP, amIMP, 4 )
lookup[0x29] = I( "AND", opAND, amIMM, 2 )
lookup[0x2A] = I( "ROL", opROL, amIMP, 2 )
lookup[0x2B] = I( "???", opXXX, amIMP, 2 )
lookup[0x2C] = I( "BIT", opBIT, amABS, 4 )
lookup[0x2D] = I( "AND", opAND, amABS, 4 )
lookup[0x2E] = I( "ROL", opROL, amABS, 6 )
lookup[0x2F] = I( "???", opXXX, amIMP, 6 )

lookup[0x30] = I( "BMI", opBMI, amREL, 2 )
lookup[0x31] = I( "AND", opAND, amIZY, 5 )
lookup[0x32] = I( "???", opXXX, amIMP, 2 )
lookup[0x33] = I( "???", opXXX, amIMP, 8 )
lookup[0x34] = I( "???", opNOP, amIMP, 4 )
lookup[0x35] = I( "AND", opAND, amZPX, 4 )
lookup[0x36] = I( "ROL", opROL, amZPX, 6 )
lookup[0x37] = I( "???", opXXX, amIMP, 6 )
lookup[0x38] = I( "SEC", opSEC, amIMP, 2 )
lookup[0x39] = I( "AND", opAND, amABY, 4 )
lookup[0x3A] = I( "???", opNOP, amIMP, 2 )
lookup[0x3B] = I( "???", opXXX, amIMP, 7 )
lookup[0x3C] = I( "???", opNOP, amIMP, 4 )
lookup[0x3D] = I( "AND", opAND, amABX, 4 )
lookup[0x3E] = I( "ROL", opROL, amABX, 7 )
lookup[0x3F] = I( "???", opXXX, amIMP, 7 )

lookup[0x40] = I( "RTI", opRTI, amIMP, 6 )
lookup[0x41] = I( "EOR", opEOR, amIZX, 6 )
lookup[0x42] = I( "???", opXXX, amIMP, 2 )
lookup[0x43] = I( "???", opXXX, amIMP, 8 )
lookup[0x44] = I( "???", opNOP, amIMP, 3 )
lookup[0x45] = I( "EOR", opEOR, amZP0, 3 )
lookup[0x46] = I( "LSR", opLSR, amZP0, 5 )
lookup[0x47] = I( "???", opXXX, amIMP, 5 )
lookup[0x48] = I( "PHA", opPHA, amIMP, 3 )
lookup[0x49] = I( "EOR", opEOR, amIMM, 2 )
lookup[0x4A] = I( "LSR", opLSR, amIMP, 2 )
lookup[0x4B] = I( "???", opXXX, amIMP, 2 )
lookup[0x4C] = I( "JMP", opJMP, amABS, 3 )
lookup[0x3D] = I( "EOR", opEOR, amABS, 4 )
lookup[0x4E] = I( "LSR", opLSR, amABS, 6 )
lookup[0x4F] = I( "???", opXXX, amIMP, 6 )

lookup[0x50] = I( "BVC", opBVC, amREL, 2 )
lookup[0x51] = I( "EOR", opEOR, amIZY, 5 )
lookup[0x52] = I( "???", opXXX, amIMP, 2 )
lookup[0x53] = I( "???", opXXX, amIMP, 8 )
lookup[0x54] = I( "???", opNOP, amIMP, 4 )
lookup[0x55] = I( "EOR", opEOR, amZPX, 4 )
lookup[0x56] = I( "LSR", opLSR, amZPX, 6 )
lookup[0x57] = I( "???", opXXX, amIMP, 6 )
lookup[0x58] = I( "CLI", opCLI, amIMP, 2 )
lookup[0x59] = I( "EOR", opEOR, amABY, 4 )
lookup[0x5A] = I( "???", opNOP, amIMP, 2 )
lookup[0x5B] = I( "???", opXXX, amIMP, 7 )
lookup[0x5C] = I( "???", opNOP, amIMP, 4 )
lookup[0x5D] = I( "EOR", opEOR, amABX, 4 )
lookup[0x5E] = I( "LSR", opLSR, amABX, 7 )
lookup[0x5F] = I( "???", opXXX, amIMP, 7 )

lookup[0x60] = I( "RTS", opRTS, amIMP, 6 )
lookup[0x61] = I( "ADC", opADC, amIZX, 6 )
lookup[0x62] = I( "???", opXXX, amIMP, 2 )
lookup[0x63] = I( "???", opXXX, amIMP, 8 )
lookup[0x64] = I( "???", opNOP, amIMP, 3 )
lookup[0x65] = I( "ADC", opADC, amZP0, 3 )
lookup[0x66] = I( "ROR", opROR, amZP0, 5 )
lookup[0x67] = I( "???", opXXX, amIMP, 5 )
lookup[0x68] = I( "PLA", opPLA, amIMP, 4 )
lookup[0x69] = I( "ADC", opADC, amIMM, 2 )
lookup[0x6A] = I( "ROR", opROR, amIMP, 2 )
lookup[0x6B] = I( "???", opXXX, amIMP, 2 )
lookup[0x6C] = I( "JMP", opJMP, amIND, 5 )
lookup[0x6D] = I( "ADC", opADC, amABS, 4 )
lookup[0x6E] = I( "ROR", opROR, amABS, 6 )
lookup[0x6F] = I( "???", opXXX, amIMP, 6 )

lookup[0x70] = I( "BVS", opBVS, amREL, 2 )
lookup[0x71] = I( "ADC", opADC, amIZY, 5 )
lookup[0x72] = I( "???", opXXX, amIMP, 2 )
lookup[0x73] = I( "???", opXXX, amIMP, 8 )
lookup[0x74] = I( "???", opNOP, amIMP, 4 )
lookup[0x75] = I( "ADC", opADC, amZPX, 4 )
lookup[0x76] = I( "ROR", opROR, amZPX, 6 )
lookup[0x77] = I( "???", opXXX, amIMP, 6 )
lookup[0x78] = I( "SEI", opSEI, amIMP, 2 )
lookup[0x79] = I( "ADC", opADC, amABY, 4 )
lookup[0x7A] = I( "???", opNOP, amIMP, 2 )
lookup[0x7B] = I( "???", opXXX, amIMP, 7 )
lookup[0x7C] = I( "???", opNOP, amIMP, 4 )
lookup[0x7D] = I( "ADC", opADC, amABX, 4 )
lookup[0x7E] = I( "ROR", opROR, amABX, 7 )
lookup[0x7F] = I( "???", opXXX, amIMP, 7 )

lookup[0x80] = I( "???", opNOP, amIMP, 2 )
lookup[0x81] = I( "STA", opSTA, amIZX, 6 )
lookup[0x82] = I( "???", opNOP, amIMP, 2 )
lookup[0x83] = I( "???", opXXX, amIMP, 6 )
lookup[0x84] = I( "STY", opSTY, amZP0, 3 )
lookup[0x85] = I( "STA", opSTA, amZP0, 3 )
lookup[0x86] = I( "STX", opSTX, amZP0, 3 )
lookup[0x87] = I( "???", opXXX, amIMP, 3 )
lookup[0x88] = I( "DEY", opDEY, amIMP, 2 )
lookup[0x89] = I( "???", opNOP, amIMP, 2 )
lookup[0x8A] = I( "TXA", opTXA, amIMP, 2 )
lookup[0x8B] = I( "???", opXXX, amIMP, 2 )
lookup[0x8C] = I( "STY", opSTY, amABS, 4 )
lookup[0x8D] = I( "STA", opSTA, amABS, 4 )
lookup[0x8E] = I( "STX", opSTX, amABS, 4 )
lookup[0x8F] = I( "???", opXXX, amIMP, 4 )

lookup[0x90] = I( "BCC", opBCC, amREL, 2 )
lookup[0x91] = I( "STA", opSTA, amIZY, 6 )
lookup[0x92] = I( "???", opXXX, amIMP, 2 )
lookup[0x93] = I( "???", opXXX, amIMP, 6 )
lookup[0x94] = I( "STY", opSTY, amZPX, 4 )
lookup[0x95] = I( "STA", opSTA, amZPX, 4 )
lookup[0x96] = I( "STX", opSTX, amZPY, 4 )
lookup[0x97] = I( "???", opXXX, amIMP, 4 )
lookup[0x98] = I( "TYA", opTYA, amIMP, 2 )
lookup[0x99] = I( "STA", opSTA, amABY, 5 )
lookup[0x9A] = I( "TXS", opTXS, amIMP, 2 )
lookup[0x9B] = I( "???", opXXX, amIMP, 5 )
lookup[0x9C] = I( "???", opNOP, amIMP, 5 )
lookup[0x9D] = I( "STA", opSTA, amABX, 5 )
lookup[0x9E] = I( "???", opXXX, amIMP, 5 )
lookup[0x9F] = I( "???", opXXX, amIMP, 5 )

lookup[0xA0] = I( "LDY", opLDY, amIMM, 2 )
lookup[0xA1] = I( "LDA", opLDA, amIZX, 6 )
lookup[0xA2] = I( "LDX", opLDX, amIMM, 2 )
lookup[0xA3] = I( "???", opXXX, amIMP, 6 )
lookup[0xA4] = I( "LDY", opLDY, amZP0, 3 )
lookup[0xA5] = I( "LDA", opLDA, amZP0, 3 )
lookup[0xA6] = I( "LDX", opLDX, amZP0, 3 )
lookup[0xA7] = I( "???", opXXX, amIMP, 3 )
lookup[0xA8] = I( "TAY", opTAY, amIMP, 2 )
lookup[0xA9] = I( "LDA", opLDA, amIMM, 2 )
lookup[0xAA] = I( "TAX", opTAX, amIMP, 2 )
lookup[0xAB] = I( "???", opXXX, amIMP, 2 )
lookup[0xAC] = I( "LDY", opLDY, amABS, 4 )
lookup[0xAD] = I( "LDA", opLDA, amABS, 4 )
lookup[0xAE] = I( "LDX", opLDX, amABS, 4 )
lookup[0xAF] = I( "???", opXXX, amIMP, 4 )

lookup[0xB0] = I( "BCS", opBCS, amREL, 2 )
lookup[0xB1] = I( "LDA", opLDA, amIZY, 5 )
lookup[0xB2] = I( "???", opXXX, amIMP, 2 )
lookup[0xB3] = I( "???", opXXX, amIMP, 5 )
lookup[0xB4] = I( "LDY", opLDY, amZPX, 4 )
lookup[0xB5] = I( "LDA", opLDA, amZPX, 4 )
lookup[0xB6] = I( "LDX", opLDX, amZPY, 4 )
lookup[0xB7] = I( "???", opXXX, amIMP, 4 )
lookup[0xB8] = I( "CLV", opCLV, amIMP, 2 )
lookup[0xB9] = I( "LDA", opLDA, amABY, 4 )
lookup[0xBA] = I( "TSX", opTSX, amIMP, 2 )
lookup[0xBB] = I( "???", opXXX, amIMP, 4 )
lookup[0xBC] = I( "LDY", opLDY, amABX, 4 )
lookup[0xBD] = I( "LDA", opLDA, amABX, 4 )
lookup[0xBE] = I( "LDX", opLDX, amABY, 4 )
lookup[0xBF] = I( "???", opXXX, amIMP, 4 )

lookup[0xC0] = I( "CPY", opCPY, amIMM, 2 )
lookup[0xC1] = I( "CMP", opCMP, amIZX, 6 )
lookup[0xC2] = I( "???", opNOP, amIMP, 2 )
lookup[0xC3] = I( "???", opXXX, amIMP, 8 )
lookup[0xC4] = I( "CPY", opCPY, amZP0, 3 )
lookup[0xC5] = I( "CMP", opCMP, amZP0, 3 )
lookup[0xC6] = I( "DEC", opDEC, amZP0, 5 )
lookup[0xC7] = I( "???", opXXX, amIMP, 5 )
lookup[0xC8] = I( "INY", opINY, amIMP, 2 )
lookup[0xC9] = I( "CMP", opCMP, amIMM, 2 )
lookup[0xCA] = I( "DEX", opDEX, amIMP, 2 )
lookup[0xCB] = I( "???", opXXX, amIMP, 2 )
lookup[0xCC] = I( "CPY", opCPY, amABS, 4 )
lookup[0xCD] = I( "CMP", opCMP, amABS, 4 )
lookup[0xCE] = I( "DEC", opDEC, amABS, 6 )
lookup[0xCF] = I( "???", opXXX, amIMP, 6 )

lookup[0xD0] = I( "BNE", opBNE, amREL, 2 )
lookup[0xD1] = I( "CMP", opCMP, amIZY, 5 )
lookup[0xD2] = I( "???", opXXX, amIMP, 2 )
lookup[0xD3] = I( "???", opXXX, amIMP, 8 )
lookup[0xD4] = I( "???", opNOP, amIMP, 4 )
lookup[0xD5] = I( "CMP", opCMP, amZPX, 4 )
lookup[0xD6] = I( "DEC", opDEC, amZPX, 6 )
lookup[0xD7] = I( "???", opXXX, amIMP, 6 )
lookup[0xD8] = I( "CLD", opCLD, amIMP, 2 )
lookup[0xD9] = I( "CMP", opCMP, amABY, 4 )
lookup[0xDA] = I( "NOP", opNOP, amIMP, 2 )
lookup[0xDB] = I( "???", opXXX, amIMP, 7 )
lookup[0xDC] = I( "???", opNOP, amIMP, 4 )
lookup[0xDD] = I( "CMP", opCMP, amABX, 4 )
lookup[0xDE] = I( "DEC", opDEC, amABX, 7 )
lookup[0xDF] = I( "???", opXXX, amIMP, 7 )

lookup[0xE0] = I( "CPX", opCPX, amIMM, 2 )
lookup[0xE1] = I( "SBC", opSBC, amIZX, 6 )
lookup[0xE2] = I( "???", opNOP, amIMP, 2 )
lookup[0xE3] = I( "???", opXXX, amIMP, 8 )
lookup[0xE4] = I( "CPX", opCPX, amZP0, 3 )
lookup[0xE5] = I( "SBC", opSBC, amZP0, 3 )
lookup[0xE6] = I( "INC", opINC, amZP0, 5 )
lookup[0xE7] = I( "???", opXXX, amIMP, 5 )
lookup[0xE8] = I( "INX", opINX, amIMP, 2 )
lookup[0xE9] = I( "SBC", opSBC, amIMM, 2 )
lookup[0xEA] = I( "NOP", opNOP, amIMP, 2 )
lookup[0xEB] = I( "???", opSBC, amIMP, 2 )
lookup[0xEC] = I( "CPX", opCPX, amABS, 4 )
lookup[0xED] = I( "SBC", opSBC, amABS, 4 )
lookup[0xEE] = I( "INC", opINC, amABS, 6 )
lookup[0xEF] = I( "???", opXXX, amIMP, 6 )

lookup[0xF0] = I( "BEQ", opBEQ, amREL, 2 )
lookup[0xF1] = I( "SBC", opSBC, amIZY, 5 )
lookup[0xF2] = I( "???", opXXX, amIMP, 2 )
lookup[0xF3] = I( "???", opXXX, amIMP, 8 )
lookup[0xF4] = I( "???", opNOP, amIMP, 4 )
lookup[0xF5] = I( "SBC", opSBC, amZPX, 4 )
lookup[0xF6] = I( "INC", opINC, amZPX, 6 )
lookup[0xF7] = I( "???", opXXX, amIMP, 6 )
lookup[0xF8] = I( "SED", opSED, amIMP, 2 )
lookup[0xF9] = I( "SBC", opSBC, amABY, 4 )
lookup[0xFA] = I( "NOP", opNOP, amIMP, 2 )
lookup[0xFB] = I( "???", opXXX, amIMP, 7 )
lookup[0xFC] = I( "???", opNOP, amIMP, 4 )
lookup[0xFD] = I( "SBC", opSBC, amABX, 4 )
lookup[0xFE] = I( "INC", opINC, amABX, 7 )
lookup[0xFF] = I( "???", opXXX, amIMP, 7 )
