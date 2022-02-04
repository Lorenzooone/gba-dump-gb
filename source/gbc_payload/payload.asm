    INCLUDE "hardware.inc"            ; system defines

    SECTION "Start",ROM0[$0]        ; start vector, followed by header data applied by rgbfix.exe
    
start:
    xor a
    ld  [rLCDC],a

.copy_to_hram
    ld  hl,_VRAM+.hram_section
    ld  c,$80
.copy_hram_loop
    ld  a,[hl+]
    ld  [$ff00+c],a
    inc c
    jr  nz,.copy_hram_loop

.jump_to_hram
    ld  hl,$0101                       ; chosen target byte
    jp  $FF80

.hram_section
    ld  a,LCDCF_ON
    ld  [rLCDC],a
.main_loop
    ld  b,$C
.inner_loop
    xor a
    ld  [rIF],a
    inc a
    ld  [rIE],a
    jr  .wait_interrupt
.reproduce_sound
    dec b
    jr  nz,.inner_loop
    ld  a,$FF
    ld  [rNR50],a
    ld  [rNR51],a
    ld  [rNR52],a
    ld  a,[hl]
    ld  [rNR12],a
    ld  [rNR13],a
    ld  [rNR14],a
    jr  .main_loop
.wait_interrupt
    ld  a,[rIF]
    and a,$1
    jr  z,.wait_interrupt
    jr  .reproduce_sound