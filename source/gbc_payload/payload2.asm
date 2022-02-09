    INCLUDE "hardware.inc"             ; system defines

rROM_TRANSFER EQU $1
rSRAM_TRANSFER EQU $2
rMASTER_MODE EQU $81
rOK  EQU $1
rFAIL EQU $0
rBASE_VAL EQU $10

    SECTION "Start",ROM0[$0]           ; start vector, followed by header data applied by rgbfix.exe
    
start:
    xor a
    ld  [rLCDC],a
    
    ld  a,$10                          ; read P15 - returns a, b, select, start
    ld  [rP1],a
.wait_for_a
    ld  a,[rP1]
    cpl
    and a,$0F
    cp  a,PADF_A
    jr  nz,.wait_for_a
    xor a
	ld	[rSCX],a
	ld	[rSCY],a
    ld  sp,$FFFE                       ; setup stack
    ld  a,$30                          ; read P15 - returns a, b, select, start
    ld  [rP1],a
    ld  a,$80
    ld  [rBCPS],a
    ld  [rOCPS],a
    ld  [rOBP0],a
    ld  [rOBP1],a
    ld  [$FF4C],a                      ; set as GBC+DMG

.init_palette
    ld  b,$10
    ld  hl,_VRAM+palette
.palette_loop_obj
    ld  a,[hl+]
    ld  [rOCPD],a
    dec b
    jr  nz,.palette_loop_obj
    ld  b,$8
.palette_loop_bg
    ld  a,[hl+]
    ld  [rBCPD],a
    dec b
    jr  nz,.palette_loop_bg
    ld  a,$FC
    ld  [rBGP],a

.init_arrangements
    ld hl,_VRAM+emptyTile
    ld b,[hl]
    ld de,$0240
    ld hl,$9C00
.arrangements_loop
    ld  a,b
    ld [hl+],a
    dec de
    ld  a,d
    or  a,e
    jr  nz,.arrangements_loop

.copy_to_hram
    ld  hl,_VRAM+hram_code
.copy_to_hram_exec
    ld  c,$80
    ld  b,$7F
.copy_hram_loop
    ld  a,[hl+]
    ld  [$ff00+c],a
    inc c
    dec b
    jr  nz,.copy_hram_loop

.jump_to_hram
    ld  e,$00
    ld  b,$FF
    jp  $FF80

SECTION "HRAM",ROM0
hram_code:
    ld  a,LCDCF_ON | LCDCF_BG8000 | LCDCF_BG9C00 | LCDCF_OBJ8 | LCDCF_OBJOFF | LCDCF_WINOFF | LCDCF_BGON
    ld  [rLCDC],a
.main_loop
.inner_loop
    xor a
    ld  [rIF],a
    inc a
    ld  [rIE],a
    jr  .wait_interrupt
    
.render_and_input
    ld  hl,$9C00
    ld  d,$00
    add hl,de
    call $FF80-hram_code+.wait_VRAM_accessible
    ld  a,b
    swap a
    and a,$0F
    add a,$80
    ld  [hl+],a
    ld  a,b
    and a,$0F
    add a,$80
    ld  [hl+],a
    ld  a,e
    add a,$4
    ld  e,a
    call $FF80-hram_code+.send_nybble
    ld  h,a
    swap h
    call $FF80-hram_code+.send_nybble
    or  a,h
    ld   b,a
    jr  .main_loop

.send_nybble
    swap b
.resend_nybble
    ld  a,b
    and a,$0F
    ld  [rSB],a
    ld  a,rMASTER_MODE
    ld  [rSC],a
.wait_end
    ld  a,[rSC]
    bit 7,a
    jr  nz,.wait_end
    ld  c,$FF
.wait_sync
    dec c
    jr  nz,.wait_sync
    ld  a,[rSB]
    ld  c,a
    and a,$F0
    cp  a,rBASE_VAL
    jr  nz,.resend_nybble
    ld  a,c
    and a,$0F
    ret

.wait_interrupt
    ld  a,[rIF]
    and a,$1
    jr  z,.wait_interrupt
    jr  .render_and_input
    
.wait_VRAM_accessible
    push hl
    ld  hl,rSTAT
.wait
    bit 1,[hl]                         ; Wait until Mode is 0 or 1
    jr  nz,.wait
    pop hl
    ret

.end_hram_code
ASSERT (.end_hram_code - hram_code) < ($72) ; calling functions consumes a bit of the available space

    SECTION "LOGO",ROM0
logoData:
INCBIN "logo.bin"

    SECTION "Base_Arrangement",ROM0
emptyTile:
DB $10+$80

    SECTION "Palette",ROM0
palette:
INCBIN "palette.bin"

SECTION "Graphics",ROM0[$800]
INCBIN "font_2bpp.bin"
    