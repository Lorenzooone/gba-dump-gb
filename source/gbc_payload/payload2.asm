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
    call _VRAM+.send_byte_start        ; wait start, gets type
    ld  b,a
    call _VRAM+.wait                   ; wait for the other CPU
    ld  a,b
    call _VRAM+.send_byte              ; gets size
    ld  b,a
    call _VRAM+.wait                   ; wait for the other CPU
    ld  a,b
    call _VRAM+.send_byte              ; sends size back
    ld  b,a
    call _VRAM+.wait                   ; wait for the other CPU
    ld  a,b
    call _VRAM+.send_byte              ; gets result
    jr  .transmission_cycle
    
    
.send_byte_start
    xor a
    ld  [rIF],a
    ld  a,IEF_SERIAL
    ld  [rIE],a
    xor a
    ld  [rSB],a
    ld  a,rMASTER_MODE
    ld  [rSC],a
.wait_interrupt_start
    ld  a,[rIF]
    and a,IEF_SERIAL
    jr  z,.wait_interrupt_start

    ld  a,[rSB]
    cp  a,rROM_TRANSFER
    jr  z,.success_start
    cp  a,rSRAM_TRANSFER
    jr  nz,.send_byte_start
    
.success_start
    ret
    
.send_byte
    ld  h,a
    xor a
    ld  [rIF],a
    ld  a,IEF_SERIAL
    ld  [rIE],a
    ld  a,h
    ld  [rSB],a
    ld  a,rMASTER_MODE
    ld  [rSC],a
.wait_interrupt
    ld  a,[rIF]
    and a,IEF_SERIAL
    jr  z,.wait_interrupt

    ld  a,[rSB]
    ret

.wait
    ld  hl,$0000
.wait_cycle
    inc hl
    ld  a,h
    or  a,l
    jr  nz,.wait_cycle
    ret
    