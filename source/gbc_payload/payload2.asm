    INCLUDE "hardware.inc"             ; system defines

rROM_TRANSFER EQU $1
rSRAM_TRANSFER EQU $2
rMASTER_MODE EQU $81
rOK  EQU $1
rFAIL EQU $0

    SECTION "Start",ROM0[$0]           ; start vector, followed by header data applied by rgbfix.exe
    
start:
    xor a
    ld  [rLCDC],a
    ld  sp,$FFFE                       ; setup stack
.transmission_cycle
    call _VRAM+.send_byte              ; wait start, gets type
    ld  h,a
    jr  .transmission_cycle
    
.send_byte
    push bc
    call _VRAM+.send_nybble
    ld  b,a
    swap b
    call _VRAM+.send_nybble
    or a,b
    pop bc
    ret

.send_nybble
    swap h
.resend_nybble
    xor a
    ld  [rIF],a
    ld  a,IEF_SERIAL
    ld  [rIE],a
    ld  a,h
    and a,$0F
    ld  [rSB],a
    ld  a,rMASTER_MODE
    ld  [rSC],a
.wait_interrupt
    ld  a,[rIF]
    and a,IEF_SERIAL
    jr  z,.wait_interrupt
    ld  a,[rSB]
    ld  c,a
    and a,$0F
    cp  a,c
    jr  nz,.resend_nybble
    ret