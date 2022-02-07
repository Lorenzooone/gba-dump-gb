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
    ld  a,$1
    ld  [$FF4F],a
    ld  de,rHDMA1
    ld  hl,hdma_data
    ld  c,$5
.hdma_transfer1
    ld  a,[hl+]
    ld  [de],a
    inc de
    dec c
    jr  nz,.hdma_transfer1
    ld  de,rHDMA1
    ld  hl,hdma_data2
    ld  c,$5
.hdma_transfer2
    ld  a,[hl+]
    ld  [de],a
    inc de
    dec c
    jr  nz,.hdma_transfer2
    xor a
    ld  [$FF4F],a
    ld  de,rHDMA1
    ld  hl,hdma_data
    ld  c,$5
.hdma_transfer3
    ld  a,[hl+]
    ld  [de],a
    inc de
    dec c
    jr  nz,.hdma_transfer3
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
    
.check_logo
    ld  hl,$0104                       ; Start of the Nintendo logo
    ld  b,$30                          ; Nintendo logo's size
    ld  de,_VRAM+logoData
.check_logo_loop
    call $FF80+.wait_VRAM_accessible-hram_code
    ld  a,[de]
    cp  [hl]
    jr  nz,.failure
    inc de
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
    jr  nz,.failure

.success
    ld  a,$1
    call $FF80+.change_arrangements-hram_code
    ld  a,[rP1]                        ; read input
    cpl
    and a,PADF_A|PADF_B|PADF_START
    jr  z,.main_loop
    call $FF80+.wait_VRAM_accessible-hram_code
    xor a
    ld  [rLCDC],a
    jp  _VRAM+start.copy_to_hram2
    
.failure
    xor a
    call $FF80+.change_arrangements-hram_code
    jr  .main_loop
    
.wait_VRAM_accessible
    push hl
    ld  hl,rSTAT
.wait
    bit 1,[hl]                         ; Wait until Mode is 0
    jr  nz,.wait
    pop hl
    ret

.change_arrangements
    and a,$1
    jr  z,.load_waiting_arrangements
    
    ld  de,_VRAM+confirmedArrangements
    jr  .chosen_arrangements
    
.load_waiting_arrangements
    ld  de,_VRAM+waitArrangements
    
.chosen_arrangements
    ld  b,$C0                          ; Arrangements' size
    ld  hl,$9C00+$C0
.change_arrangements_loop
    call $FF80+.wait_VRAM_accessible-hram_code
    ld   a,[de]
    add  a,$80
    ld   [hl+],a
    inc  de
    dec  b
    jr   nz,.change_arrangements_loop
    ret

.wait_interrupt
    ld  a,[rIF]
    and a,$1
    jr  z,.wait_interrupt
    jr  .check_logo
    
.end_hram_code
ASSERT (.end_hram_code - hram_code) < ($7E - ($2 * $3)) ; calling functions consumes a bit of the available space

    SECTION "LOGO",ROM0
logoData:
INCBIN "logo.bin"

    SECTION "Base_Arrangement",ROM0
emptyTile:
DB $67+$80
waitArrangements:
INCBIN "ui_arrangements_wait.bin"
confirmedArrangements:
INCBIN "ui_arrangements_confirmed.bin"

    SECTION "Palette",ROM0
palette:
INCBIN "palette.bin"

hdma_data:
DB $D3,$00,$98,$A0,$12
hdma_data2:
DB $D3,$00,$80,$00,$40

SECTION "Graphics",ROM0[$800]
INCBIN "ui_graphics.bin"
