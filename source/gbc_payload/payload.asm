    INCLUDE "hardware.inc"             ; system defines

    SECTION "Start",ROM0[$0]           ; start vector, followed by header data applied by rgbfix.exe
    
start:
    xor a
    ld  [rLCDC],a
	ld	[rSCX],a
	ld	[rSCY],a
    ld  sp,$FFFC                       ; setup stack
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
    xor a
    ld  [$FFFD],a
    ld  [$FFFE],a
    jp  $FF80
    
.copy_to_hram2
    ld  hl,_VRAM+.start_comunication
    jr  .copy_to_hram_exec
    
.start_comunication
    xor a
    ld  hl,$FE00
    ld  c,$A0
.blank_oam
    ld  [hl+],a
    dec c
    jr nz,.blank_oam
    ld  a,$04
    ld  [$FF4C],a                      ; set as DMG
    ld  a,$01
    ld  [$FF6C],a                      ; set as DMG
    xor a
    ld  [$FF70],a
    ld  a,$11
    ld  [$FF50],a                      ; set as DMG
    ld  a,$91
    ld  [rLCDC],a
    jp  $0100
    
.ret
    ret
    
.read_input
    ld  a,$10                          ; read P15 - returns a, b, select, start
    ld  [rP1],a
    ld  a,[rP1]                        ; read input
    cpl
    and a,PADF_A|PADF_B|PADF_START|PADF_SELECT
    jr  z,.ret
    rla
    ld  d,$00
    ld  e,a
    ld  hl,_VRAM+inputData
    add hl,de
    ld  a,[hl+]
    ld  d,a
    ld  a,[hl+]
    ld  e,a
    
.update_val
    ld  a,[$FFFD]
    ld  h,a
    ld  a,[$FFFE]
    ld  l,a
    add hl,de
    ld  a,h
    ld  [$FFFD],a
    ld  a,l
    ld  [$FFFE],a
    ret
    
.render_number
    ld  a,b
    swap a
    and a,$0F
    add a,$80
    ld  [hl+],a
    ld  a,b
    and a,$0F
    add a,$80
    ld  [hl+],a
    ret

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
    call $FF80+.change_arrangements-hram_code
    call $FF80-hram_code+.wait_VRAM_accessible
    call _VRAM+start.read_input
    jr  .main_loop
    
.wait_VRAM_accessible
    push hl
    ld  hl,rSTAT
.wait
    bit 1,[hl]                         ; Wait until Mode is 0 or 1
    jr  nz,.wait
    pop hl
    ret

.change_arrangements
    ld  hl,$9C00
    ld  b,$12/2
    ld  a,[$FFFD]
    ld  d,a
    ld  a,[$FFFE]
    ld  e,a
.change_arrangements_row
    call $FF80-hram_code+.render_raw_number
    ld  c,$4
.change_arrangements_single
    inc hl
    call $FF80-hram_code+.render_load_number
    dec c
    jr  nz,.change_arrangements_single
    push de
    ld  de,$30
    add hl,de
    pop de
    dec b
    jr  nz,.change_arrangements_row
    ret
    
.render_load_number
    push bc
    ld  a,[de]
    ld  b,a
    call $FF80-hram_code+.wait_VRAM_accessible
    call _VRAM+start.render_number
    inc de
    pop bc
    ret
    
.render_raw_number
    push bc
    ld b,d
    call $FF80-hram_code+.wait_VRAM_accessible
    call _VRAM+start.render_number
    ld b,e
    call $FF80-hram_code+.wait_VRAM_accessible
    call _VRAM+start.render_number
    pop bc
    ret

.wait_interrupt
    ld  a,[rIF]
    and a,$1
    jr  z,.wait_interrupt
    jr  .render_and_input
    
.end_hram_code
ASSERT (.end_hram_code - hram_code) < ($72) ; calling functions consumes a bit of the available space

    SECTION "LOGO",ROM0
logoData:
INCBIN "logo.bin"

    SECTION "Base_Arrangement",ROM0
emptyTile:
DB $10+$80

    SECTION "Input_Data",ROM0
inputData:
INCBIN "sum_values.bin"

    SECTION "Palette",ROM0
palette:
INCBIN "palette.bin"

SECTION "Graphics",ROM0[$800]
INCBIN "font_2bpp.bin"
