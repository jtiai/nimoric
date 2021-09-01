# VIA6522 emulation
import datatypes
import device

const
  IORB = 0x00'u8
  IORA = 0x01'u8
  DDRB = 0x02'u8
  DDRA = 0x03'u8
  T1CL = 0x04'u8
  T1CH = 0x05'u8
  T1LL = 0x06'u8
  T1LH = 0x07'u8
  T2CL = 0x08'u8
  T2CH = 0x09'u8
  SR = 0x0A'u8
  ACR = 0x0B'u8
  PCR = 0x0C'u8
  IFR = 0x0D'u8
  IER = 0x0E'u8
  IORA2 = 0x0F'u8

  PCRF_CA1CON = (1 shl 0)
  PCRF_CA2CON = 0x0e
  PCRF_CB1CON = (1 shl 4)
  PCRF_CB2CON = 0xe0

  ACRF_PALATCH = (1 shl 0)
  ACRF_PBLATCH = (1 shl 1)
  ACRF_SRCON   = 0x1c
  ACRF_T2CON   = (1 shl 5)
  ACRF_T1CON   = 0xc0

  VIRQF_CA2 = (1 shl 0)
  VIRQF_CA1 = (1 shl 1)
  VIRQF_SR = (1 shl 2)
  VIRQF_CB2 = (1 shl 3)
  VIRQF_CB1 = (1 shl 4)
  VIRQF_T2 = (1 shl 5)
  VIRQF_T1 = (1 shl 6)

  RS0 = (1'u64 shl 0)
  RS1 = (1'u64 shl 1)
  RS2 = (1'u64 shl 2)
  RS3 = (1'u64 shl 3)
  RS_PINS = 0x0F'u64

  D0 = (1'u64 shl 16)
  D1 = (1'u64 shl 17)
  D2 = (1'u64 shl 18)
  D3 = (1'u64 shl 19)
  D4 = (1'u64 shl 20)
  D5 = (1'u64 shl 21)
  D6 = (1'u64 shl 22)
  D7 = (1'u64 shl 23)
  DB_PINS = 0xFF0000'u64

  RW = (1'u64 shl 24)
  IRQ = (1'u64 shl 26)

  CS1 = (1'u64 shl 40)
  CS2 = (1'u64 shl 41)

  CA1 = (1'u64 shl 42)
  CA2 = (1'u64 shl 43)
  CB1 = (1'u64 shl 44)
  CB2 = (1'u64 shl 45)
  CA_PINS = (CA1 or CA2)
  CB_PINS = (CB1 or CB2)

  PA0 = (1'u64 shl 48)
  PA1 = (1'u64 shl 49)
  PA2 = (1'u64 shl 50)
  PA3 = (1'u64 shl 51)
  PA4 = (1'u64 shl 52)
  PA5 = (1'u64 shl 53)
  PA6 = (1'u64 shl 54)
  PA7 = (1'u64 shl 55)
  PA_PINS = (PA0 or PA1 or PA2 or PA3 or PA4 or PA5 or PA6 or PA7)

  PB0 = (1'u64 shl 56)
  PB1 = (1'u64 shl 57)
  PB2 = (1'u64 shl 58)
  PB3 = (1'u64 shl 59)
  PB4 = (1'u64 shl 60)
  PB5 = (1'u64 shl 61)
  PB6 = (1'u64 shl 62)
  PB7 = (1'u64 shl 63)
  PB_PINS = (PB0 or PB1 or PB2 or PB3 or PB4 or PB5 or PB6 or PB7)

  IRQ_CA2 = (1'u8 shl 0)
  IRQ_CA1 = (1'u8 shl 1)
  IRQ_SR = (1'u8 shl 2)
  IRQ_CB2 = (1'u8 shl 3)
  IRQ_CB1 = (1'u8 shl 4)
  IRQ_T2 = (1'u8 shl 5)
  IRQ_T1 = (1'u8 shl 6)
  IRQ_ANY = (1'u8 shl 7)

  PIP_TIMER_COUNT = 0
  PIP_TIMER_LOAD = 8
  PIP_IRQ = 0

type
  Port = object
    inpr: uint8
    outr: uint8
    ddr: uint8
    pins: uint8
    c1In: bool
    c1Out: bool
    c1Triggered: bool
    c2In: bool
    c2Out: bool
    c2Triggered: bool

  Timer = object
    latch: uint16
    counter: uint16
    tBit: bool
    tOut: bool
    pip: uint16

  Interrupt = object
    ier: uint8
    ifr: uint8
    pip: uint16

  VIA6522* = ref object of Device
    pa: Port
    pb: Port
    t1: Timer
    t2: Timer
    intr: Interrupt
    acr: uint8
    pcr: uint8
    pins: uint64

template GET_DATA(pins: uint64): uint8 = (pins shr 16).uint8
template SET_DATA(pins: uint64, d: uint8) = pins = (pins and 0xFF0000'u64).uint64 or (d.uint64 shl 16).uint64
template GET_PA(pins: uint64): uint8 = (pins shr 48).uint8
template GET_PB(pins: uint64): uint8 = (pins shr 56).uint8
template SET_PA(pins: uint64, a: uint8) = (pins = (pins and 0xFF00FFFFFFFFFFFF'u64) or (a.uint64 shl 48))
template SET_PB(pins: uint64, b: uint8) = (pins = (pins and 0x00FFFFFFFFFFFFFF'u64) or (b.uint64 shl 56))
template SET_PAB(pins: uint64, a: uint8, b: uint8) = (pins = (pins and 0x0000FFFFFFFFFFFF'u64) or (a.uint64 shl 48) or (b.uint64 shl 56))

# Test macros
template PCR_CA1_LOW_TO_HIGH(via: VIA6522): bool = bool(via.pcr and 0x01'u8)
template PCR_CA1_HIGH_TO_LOW(via: VIA6522): bool = bool(not (via.pcr and 0x01'u8))
template PCR_CB1_LOW_TO_HIGH(via: VIA6522): bool = bool(via.pcr and 0x10'u8)
template PCR_CB1_HIGH_TO_LOW(via: VIA6522): bool = bool(not (via.pcr and 0x10'u8))
template PCR_CA2_INPUT(via: VIA6522): bool = bool(via.pcr and 0x08'u8)
template PCR_CA2_LOW_TO_HIGH(via: VIA6522): bool = (via.pcr and 0x0C'u8) == 0x04'u8
template PCR_CA2_HIGH_TO_LOW(via: VIA6522): bool = (via.pcr and 0x0C'u8) == 0x00'u8
template PCR_CA2_IND_IRQ(via: VIA6522): bool = bool(via.pcr and 0x0A'u8)
template PCR_CA2_OUTPUT(via: VIA6522): bool = bool(via.pcr and 0x08'u8)
template PCR_CA2_AUTO_HS(via: VIA6522): bool = (via.pcr and 0x0C'u8) == 0x08'u8
template PCR_CA2_HS_OUTPUT(via: VIA6522): bool = (via.pcr and 0x0E'u8) == 0x08'u8
template PCR_CA2_PULSE_OUTPUT(via: VIA6522): bool = (via.pcr and 0x0E'u8) == 0x0A'u8
template PCR_CA2_FIX_OUTPUT(via: VIA6522): bool = (via.pcr and 0x0C'u8) == 0x0C'u8
template PCR_CA2_OUTPUT_LEVEL(via: VIA6522): bool = bool((via.pcr and 0x02'u8) shr 1)
template PCR_CB2_INPUT(via: VIA6522): bool = bool(not (via.pcr and 0x80'u8))
template PCR_CB2_LOW_TO_HIGH(via: VIA6522): bool = (via.pcr and 0xC0'u8) == 0x40'u8
template PCR_CB2_HIGH_TO_LOW(via: VIA6522): bool = (via.pcr and 0x01'u8) == 0x00'u8
template PCR_CB2_IND_IRQ(via: VIA6522): bool = (via.pcr and 0xA0'u8) == 0x20'u8
template PCR_CB2_OUTPUT(via: VIA6522): bool = bool(via.pcr and 0x80'u8)
template PCR_CB2_AUTO_HS(via: VIA6522): bool = (via.pcr and 0xC0'u8) == 0x80'u8
template PCR_CB2_HS_OUTPUT(via: VIA6522): bool = (via.pcr and 0xE0'u8) == 0x80'u8
template PCR_CB2_PULSE_OUTPUT(via: VIA6522): bool = (via.pcr and 0xE0'u8) == 0xA0'u8
template PCR_CB2_FIX_OUTPUT(via: VIA6522): bool = (via.pcr and 0xC0'u8) == 0xC0'u8
template PCR_CB2_OUTPUT_LEVEL(via: VIA6522): bool = bool((via.pcr and 0x20'u8) shr 5)

template ACR_PA_LATCH_ENABLE(via: VIA6522): bool = bool(via.acr and 0x01'u8)
template ACR_PB_LATCH_ENABLE(via: VIA6522): bool = bool(via.acr and 0x02'u8)
template ACR_SR_DISABLED(via: VIA6522): bool = bool(not (via.acr and 0x1C'u8))
template ACR_SI_T2_CONTROL(via: VIA6522): bool = (via.acr and 0x1C'u8) = 0x04'u8
template ACR_SI_O2_CONTROL(via: VIA6522): bool = (via.acr and 0x1C'u8) = 0x08'u8
template ACR_SI_EXT_CONTROL(via: VIA6522): bool = (via.acr and 0x1C'u8) = 0x0C'u8
template ACR_SO_T2_RATE(via: VIA6522): bool = (via.acr and 0x1C'u8) = 0x10'u8
template ACR_SO_T2_CONTROL(via: VIA6522): bool = (via.acr and 0x1C'u8) = 0x14'u8
template ACR_SO_O2_CONTROL(via: VIA6522): bool = (via.acr and 0x1C'u8) = 0x18'u8
template ACR_SO_EXT_CONTROL(via: VIA6522): bool = (via.acr and 0x1C'u8) = 0x1C'u8
template ACR_T1_SET_PB7(via: VIA6522): bool = bool(via.acr and 0x80'u8)
template ACR_T1_CONTINOUS(via: VIA6522): bool = bool(via.acr and 0x40'u8)
template ACR_T2_COUNT_PB6(via: VIA6522): bool = bool(via.acr and 0x20'u8)

func new6522*(s: uint16): VIA6522 =
  result = new VIA6522
  result.startAddress = s
  result.endAddress = s + 0x000F'u16

func init*(via: VIA6522, isReset: bool=false) =
  # Port A init
  via.pa.inpr = 0xFF'u8
  via.pa.outr = 0x00'u8
  via.pa.ddr = 0x00'u8
  via.pa.pins = 0x00'u8
  via.pa.c1In = false
  via.pa.c1Out = true
  via.pa.c1Triggered = false
  via.pa.c2In = false
  via.pa.c2Out = true
  via.pa.c2Triggered = false
  # Port B init
  via.pb.inpr = 0xFF'u8
  via.pb.outr = 0x00'u8
  via.pb.ddr = 0x00'u8
  via.pb.pins = 0x00'u8
  via.pb.c1In = false
  via.pb.c1Out = true
  via.pb.c1Triggered = false
  via.pb.c2In = false
  via.pb.c2Out = true
  via.pb.c2Triggered = false
  # Timer 1 init
  if not isReset:
    via.t1.latch = 0xFFFF'u16
    via.t1.counter = 0x0000'u16
    via.t1.tBit = false
  via.t1.tOut = false
  via.t1.pip = 0x0000'u16
  # Timer 2 init
  if not isReset:
    via.t2.latch = 0xFFFF'u16
    via.t2.counter = 0x0000'u16
    via.t2.tBit = false
  via.t2.tOut = false
  via.t2.pip = 0x0000'u16
  # Interrupts
  via.intr.ier = 0x00'u8
  via.intr.ifr = 0x00'u8
  via.intr.pip = 0x0000'u16
  via.acr = 0x00'u8
  via.pcr = 0x00'u8

# Deplay pipeline macros
template PIP_SET(pip: uint16, offset: uint8, pos: uint8) = pip = pip or (1'u16 shl (offset + pos))
template PIP_CLR(pip: uint16, offset: uint8, pos: uint8) = pip = pip and not (1'u16 shl (offset + pos))
template PIP_RESET(pip: uint16, offset: uint8) = pip = pip and not (0xFF'u16 shl offset)
template PIP_TEST(pip: uint16, offset: uint8, pos: uint8): bool = (pip and (1'u16 shl (offset + pos))) != 0

proc readPortPins(via: VIA6522, pins: uint64) =
  let newCA1 = (pins and CA1) != 0'u64
  let newCA2 = (pins and CA2) != 0'u64
  let newCB1 = (pins and CB1) != 0'u64
  let newCB2 = (pins and CB2) != 0'u64

  via.pa.c1Triggered = (via.pa.c1In != newCA1) and ((newCA1 and via.PCR_CA1_LOW_TO_HIGH()) or (newCA1 and via.PCR_CA1_HIGH_TO_LOW()))
  via.pa.c2Triggered = (via.pa.c2In != newCA2) and ((newCA2 and via.PCR_CA2_LOW_TO_HIGH()) or (newCA2 and via.PCR_CA2_HIGH_TO_LOW()))
  via.pb.c1Triggered = (via.pb.c1In != newCB1) and ((newCB1 and via.PCR_CB1_LOW_TO_HIGH()) or (newCB1 and via.PCR_CB1_HIGH_TO_LOW()))
  via.pb.c2Triggered = (via.pb.c2In != newCB2) and ((newCB2 and via.PCR_CB1_LOW_TO_HIGH()) or (newCB2 and via.PCR_CB2_HIGH_TO_LOW()))

  via.pa.c1In = newCA1
  via.pa.c2In = newCA2
  via.pb.c1In = newCB1
  via.pb.c2In = newCB2

  if via.ACR_PA_LATCH_ENABLE():
    if via.pa.c1Triggered:
      via.pa.inpr = pins.GET_PA()
  else:
    via.pa.inpr = pins.GET_PA()

  if via.ACR_PB_LATCH_ENABLE():
    if via.pb.c1Triggered:
      via.pb.inpr = pins.GET_PB
  else:
    via.pb.inpr = pins.GET_PB

proc mergePB7(via: VIA6522, data: uint8): uint8 =
  if via.ACR_T1_SET_PB7():
    result = data and (not (1'u8 shl 7))
    if via.t1.tBit:
      result = result or (1'u8 shl 7)

proc writePortPins(via: VIA6522, pins: uint64): uint64 =
  via.pa.pins = (via.pa.inpr and not via.pa.ddr) or (via.pa.outr and via.pa.ddr)
  via.pb.pins = via.mergePB7((via.pb.inpr and not via.pb.ddr) or (via.pb.outr and via.pb.ddr))
  var pins = pins
  pins.SET_PAB(via.pa.pins, via.pb.pins)
  if via.pa.c1Out:
    pins = pins or CA1
  if via.pa.c2Out:
    pins = pins or CA2
  if via.pb.c1Out:
    pins = pins or CB1
  if via.pb.c2Out:
    pins = pins or CB2
  result = pins

proc setIntr(via: VIA6522, data: uint8) =
  via.intr.ifr = via.intr.ifr or data

proc clearIntr(via: VIA6522, data: uint8) =
  via.intr.ifr = via.intr.ifr and not data
  if (via.intr.ifr and via.intr.ier and 0x7F'u8) == 0'u8:
    via.intr.ifr = via.intr.ifr and 0x7F'u8
    via.intr.pip.PIP_RESET(PIP_IRQ)

proc clearPaIntr(via: VIA6522) =
  via.clearIntr(IRQ_CA1 or (if via.PCR_CA2_IND_IRQ(): 0'u8 else: IRQ_CA2))

proc clearPbIntr(via: VIA6522) =
  via.clearIntr(IRQ_CB1 or (if via.PCR_CB2_IND_IRQ(): 0'u8 else: IRQ_CB2))

proc writeIer(via: VIA6522, data: uint8) =
  if (data and 0x80'u8) != 0:
    via.intr.ier = via.intr.ier or (data and 0x7F'u8)
  else:
    via.intr.ier = via.intr.ier and not (data and 0x7F'u8)

proc writeIfr(via: VIA6522, data: uint8) =
  var data = data
  if (data and IRQ_ANY) != 0:
    data = 0x7F'u8
  via.clearIntr(data)

proc tickT1(via: VIA6522) =
  var t = via.t1

  if t.pip.PIP_TEST(PIP_TIMER_COUNT, 0):
    dec t.counter

  t.tOut = 0xFFFF'u16 == t.counter
  if t.tOut:
    if via.ACR_T1_CONTINOUS():
      t.tBit = not t.tBit
      via.setIntr(IRQ_T1)
      t.tBit = true
    t.pip.PIP_SET(PIP_TIMER_LOAD, 1'u8)

  if PIP_TEST(t.pip, PIP_TIMER_LOAD, 0):
    t.counter = t.latch

proc tickT2(via: VIA6522, pins: uint64) =
  var t = via.t2

  if via.ACR_T2_COUNT_PB6():
    if (PB6 and (not pins and (pins xor via.pins))) != 0:
      dec t.counter
  elif PIP_TEST(t.pip, PIP_TIMER_COUNT, 0):
    dec t.counter

  t.tOut = 0xFFFF'u16 == t.counter
  if t.tOut:
    if not t.tBit:
      via.setIntr(IRQ_T2)
      t.tBit = true

proc tickPipeline(via: VIA6522) =
  PIP_SET(via.t1.pip, PIP_TIMER_COUNT, 2)
  PIP_SET(via.t2.pip, PIP_TIMER_COUNT, 2)

  if (via.intr.ifr and via.intr.ier) != 0:
    PIP_SET(via.intr.pip, PIP_IRQ, 1)

  via.t1.pip = (via.t1.pip shr 1) and 0x7F7F'u16
  via.t2.pip = (via.t2.pip shr 1) and 0x7F7F'u16
  via.intr.pip = (via.intr.pip shr 1) and 0x7F7F'u16

proc updateCab(via: VIA6522) =
  if via.pa.c1Triggered:
    via.setIntr(IRQ_CA1)
    if via.PCR_CA2_AUTO_HS():
      via.pa.c2Out = true
  if via.pa.c2Triggered and via.PCR_CA2_INPUT():
    via.setIntr(IRQ_CA2)
  if via.pb.c1Triggered:
    via.setIntr(IRQ_CB1)
    if via.PCR_CB2_AUTO_HS():
      via.pb.c2Out = true
  if via.pb.c2Triggered and via.PCR_CB2_INPUT():
    via.setIntr(IRQ_CB2)

proc updateIrq(via: VIA6522, pins: uint64): uint64 =
  var pins = pins
  if PIP_TEST(via.intr.pip, PIP_IRQ, 0):
    via.intr.ifr = via.intr.ifr or (1'u8 shl 7)

  if (via.intr.ifr and (1'u8 shl 7)) != 0:
    pins = pins or IRQ
  else:
    pins = pins and not IRQ
  result = pins

proc internalTick(via: VIA6522, pins: uint64): uint64 =
  var pins = pins
  via.readPortPins(pins)
  via.updateCab()
  via.tickT1()
  via.tickT2(pins)
  pins = via.updateIrq(pins)
  pins = via.writePortPins(pins)
  via.tickPipeline()
  result = pins

method read*(dev: VIA6522, memAddr: uint16): uint8 =
  let a: uint8 = (memAddr - dev.startAddress).uint8
  var data: uint8

  case a:
    of IORB:
      if dev.ACR_PB_LATCH_ENABLE():
        data = dev.pb.inpr
      else:
        data = dev.pb.pins
      dev.clearPbIntr()
    of IORA:
      if dev.ACR_PA_LATCH_ENABLE():
        data = dev.pa.inpr
      else:
        data = dev.pa.pins
      dev.clearPaIntr()
      if dev.PCR_CA2_PULSE_OUTPUT() and dev.PCR_CA2_AUTO_HS():
        dev.pa.c2Out = false
      if dev.PCR_CA2_PULSE_OUTPUT():
        discard  # FIXME: pulse output delay
    of DDRB:
      data = dev.pb.ddr
    of DDRA:
      data = dev.pa.ddr
    of T1CL:
      data = (dev.t1.counter and 0x00FF'u16).uint8
      dev.clearIntr(IRQ_T1)
    of T1CH:
      data = (dev.t1.counter shr 8).uint8
    of T1LL:
      data = (dev.t1.latch and 0x00FF'u16).uint8
    of T1LH:
      data = (dev.t1.latch shr 8).uint8
    of T2CL:
      data = (dev.t2.counter and 0x00FF'u16).uint8
    of T2CH:
      data = (dev.t2.counter shr 8).uint8
    of ACR:
      data = dev.acr
    of PCR:
      data = dev.pcr
    of IFR:
      data = dev.intr.ifr
    of IER:
      data = dev.intr.ier or 0x80'u8
    of IORA2:
      if dev.ACR_PA_LATCH_ENABLE():
        data = dev.pa.inpr
      else:
        data = dev.pa.pins
    else:
      echo "Invalid register"
  result = data

method write*(dev: VIA6522, memAddr: uint16, data: uint8) =
  let a: uint8 = (memAddr - dev.startAddress).uint8

  case a:
  of IORB:
    dev.pb.outr = data
    dev.clearPbIntr()
    if dev.PCR_CB2_AUTO_HS():
      dev.pb.c2Out = false
  of IORA:
    dev.pa.outr = data
    if dev.PCR_CA2_PULSE_OUTPUT() or dev.PCR_CA2_AUTO_HS():
      dev.pa.c2Out = false
    if dev.PCR_CA2_PULSE_OUTPUT():
      discard  # FIXME: pulse output delay pipeline
  of DDRB:
    dev.pb.ddr = data
  of DDRA:
    dev.pa.ddr = data
  of T1CL, T1LL:
    dev.t1.latch = (dev.t1.latch and 0xFF00'u16) or data.uint16
  of T1CH:
    dev.t1.latch = (data.uint16 shl 8) or (dev.t1.latch and 0x00FF'u16)
    dev.clearIntr(IRQ_T1)
    dev.t1.tBit = false
    dev.t1.counter = dev.t1.latch
  of T1LH:
    dev.t1.latch = (data.uint16 shl 8) or (dev.t1.latch and 0x00FF'u16)
    dev.clearIntr(IRQ_T1)
  of T2CL:
    dev.t2.latch = (dev.t2.latch and 0xFF00'u16) or data.uint16
  of T2CH:
    dev.t2.latch = (dev.t2.latch and 0x00FF'u16) or data.uint16
    dev.clearIntr(IRQ_T2)
    dev.t2.tBit = false
    dev.t2.counter = dev.t2.latch
  of SR:
    discard  # FIXME
  of ACR:
    dev.acr = data
    if dev.ACR_T2_COUNT_PB6():
      dev.t2.pip.PIP_CLR( PIP_TIMER_COUNT, 0'u8)
  of PCR:
    dev.pcr = data
    if dev.PCR_CA2_FIX_OUTPUT():
      dev.pa.c2Out = dev.PCR_CA2_OUTPUT_LEVEL()
    if dev.PCR_CB2_FIX_OUTPUT():
      dev.pb.c2Out = dev.PCR_CB2_OUTPUT_LEVEL()
  of IFR:
    dev.writeIfr(data)
  of IER:
    dev.writeIer(data)
  of IORA2:
    dev.pa.outr = data
  else:
    echo "Invalid register"

proc tick*(via: VIA6522, pins: uint64): uint64 =
  var pins = pins
  if (pins and (CS1 or CS2)) == CS1:
    let address = (pins and RS_PINS).uint16
    if (pins and RW) != 0:
      let data = via.read(address)
      pins.SET_DATA(data)
    else:
      let data = pins.GET_DATA()
      via.write(address, data)
  pins = via.internalTick(pins)
  via.pins = pins
  result = pins
