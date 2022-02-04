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
    jp  $FF80

.hram_section
    ld  a,LCDCF_ON
    ld  [rLCDC],a
.main_loop
.inner_loop
    xor a
    ld  [rIF],a
    inc a
    ld  [rIE],a
    jr  .wait_interrupt
    
.check_logo
    ld  hl,$0104                       ; Start of the Nintendo logo
    ld  b,$30                          ; Nintendo logo's size
    ld  c,$80+logoData-.hram_section
.check_logo_loop
    ld  a,[$ff00+c]
    cp  [hl]
    jr  nz,.main_loop
    inc c
    inc hl
    dec b
    jr  nz,.check_logo_loop
    
.check_header
    ld  b,$19
    ld  a,b
.check_header_loop
    add [hl]
    inc l
    dec b
    jr  nz,.check_header_loop
    add [hl]
    jr  nz,.main_loop

.success
    ld  a,$FF
    ld  [rNR50],a
    ld  [rNR51],a
    ld  [rNR52],a
    ld  a,$CE
    ld  [rNR12],a
    ld  [rNR13],a
    ld  [rNR14],a
    jr  .main_loop
    
.wait_interrupt
    ld  a,[rIF]
    and a,$1
    jr  z,.wait_interrupt
    jr  .check_logo

    SECTION "LOGO",ROM0
logoData:
INCBIN "logo.bin"