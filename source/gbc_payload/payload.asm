    INCLUDE "hardware.inc"             ; system defines

    SECTION "Start",ROM0[$0]           ; start vector, followed by header data applied by rgbfix.exe
    
start:
    xor a
    ld  [rLCDC],a
	ld	[rSCX],a
	ld	[rSCY],a
    ld  sp,$FFFE                       ; setup stack
    ld  a,$10                          ; read P15 - returns a, b, select, start
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
    ld  de,$0000
    jp  $FF80

SECTION "HRAM",ROM0[$600]
hram_code:
    ld  a,LCDCF_ON | LCDCF_BG8000 | LCDCF_BG9C00 | LCDCF_OBJ8 | LCDCF_OBJOFF | LCDCF_WINOFF | LCDCF_BGON
    ld  [rLCDC],a
.main_loop
.inner_loop
    xor a
    ld  [rIF],a
    inc a
    ld  [rIE],a
.wait_interrupt
    ld  a,[rIF]
    and a,$1
    jr  z,.wait_interrupt
    
.render_and_input
    ld  hl,$9C00
    ld  b,$12/2
    push de
.change_arrangements_row
    ld a,d
    call $FF80-hram_code+.render_number
    ld a,e
    call $FF80-hram_code+.render_number
    ld  c,$4
.change_arrangements_single
    inc hl
    ld  a,[de]
    inc de
    call $FF80-hram_code+.render_number
    dec c
    jr  nz,.change_arrangements_single
    ld  c,$30
.reach_next_row
    inc hl
    dec c
    jr  nz,.reach_next_row
    dec b
    jr  nz,.change_arrangements_row
    pop de
.read_input
    ld  a,[rP1]                        ; read input
    cpl
    and a,PADF_A|PADF_B|PADF_START|PADF_SELECT
    rla
    ld  h,(_VRAM+inputData)/$100
    ld  l,a
    call $FF80-hram_code+.wait_VRAM_accessible
    ld  a,[hl+]
    ld  b,a
    ld  a,[hl]
    ld  l,a
    ld  h,b
    add hl,de
    ld  d,h
    ld  e,l
    jr  .main_loop
    
.render_number
    push af
    swap a
    and a,$0F
    add a,$80
    call $FF80-hram_code+.wait_VRAM_accessible
    ld  [hl+],a
    pop af
    and a,$0F
    add a,$80
    ld  [hl+],a
    ret
    
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

    SECTION "Input_Data",ROM0[$700]
inputData:
INCBIN "sum_values.bin"

    SECTION "Palette",ROM0
palette:
INCBIN "palette.bin"

SECTION "Graphics",ROM0[$800]
INCBIN "font_2bpp.bin"
