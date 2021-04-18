        processor 6502

        seg.u   data
        ; Zero page
        org     $0000

        ; Normal RAM
        org     $0100

REMEND  equ     $DFFFF
        seg     code
        org     $E000

RESET   subroutine
startup:
        jmp     startup

NMI     rti

        subroutine
IRQ
        rti

        seg     vector
        org     $FFFA
        dc.w    NMI
        dc.w    RESET
        dc.W    IRQ