    INCLUDE "hardware.inc"             ; system defines

rROM_TRANSFER EQU $1
rSRAM_TRANSFER EQU $2
rSLAVE_MODE EQU $82
rOK  EQU $1
rFAIL EQU $0
rBASE_VAL EQU $10
rCHECK_VAL EQU $40

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
    ld  [$FF4C],a                      ; set as GBC+DMG
    ld  a,rBASE_VAL
    ld  [rSB],a

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
    ld  c,$80
.copy_hram_loop
    ld  a,[hl+]
    ld  [$ff00+c],a
    inc c
    jr  nz,.copy_hram_loop

.jump_to_hram
    jp  $FF80
    
.prepare_ROM_dumper
    ld  a,b
    and a,PADF_A|PADF_START
    jr  z,.prepare_SRAM_dumper
.send_start
    ld  c,rOK
    ld  a,rROM_TRANSFER
    ld  h,a
    call _VRAM+.send_byte              ; init transfer, ROM
    ld  a,[$0148]
    ld  h,a
    cp  a,$5
    jr  z,.check_mbc1
    cp  a,$6
    jr  nz,.transfer_size

.check_mbc1
    ld  a,[$0147]
    cp  a,CART_ROM_MBC1
    jr  z,.alter_val
    cp  a,CART_ROM_MBC1_RAM
    jr  z,.alter_val
    cp  a,CART_ROM_MBC1_RAM_BAT
    jr  nz,.transfer_size
    
.alter_val
    ld  a,$10
    or  a,h
    ld  h,a

.transfer_size
    ld  a,h
    call _VRAM+.send_byte              ; send ROM size
    cp  a,rROM_TRANSFER
    jr  z,.transfer_first
    ld  c,rFAIL
.transfer_first
    ld  a,h
    call _VRAM+.send_byte              ; get ROM size
    cp  a,h
    jr  z,.transfer_second
    ld  c,rFAIL
.transfer_second
    ld  h,c
    ld  a,c
    call _VRAM+.send_check_byte        ; check success
    ld  a,c
    cp  a,rFAIL
    jr  z,.send_start
    ld  de,$0000
.transfer_group
    ld  c,rOK
.transfer_single
    ld  a,[de]
    call _VRAM+.send_byte              ; send ROM data
    cp  a,h
    jr  z,.continue_transfer
    ld  c,rFAIL
.continue_transfer
    ld  a,[de]
    ld  h,a
    inc de
    ld  a,e
    cp  a,$00
    jr  nz,.transfer_single
    call _VRAM+.send_byte              ; get last one
    cp  a,h
    jr  z,.continue_transfer_outer
    ld  c,rFAIL
.continue_transfer_outer
    ld  h,c
    ld  a,c
    call _VRAM+.send_check_byte        ; check success
    ld  a,c
    cp  a,rFAIL
    jr  nz,.success_group
    dec d
    jr  .transfer_group
.success_group
    ld  a,d
    cp  a,$80
    jr  nz,.transfer_group
    jp  _VRAM+.copy_to_hram

.prepare_SRAM_dumper
    ld  a,b
    and a,PADF_B|PADF_START
    jp  z,_VRAM+.copy_to_hram
    
    jp  _VRAM+.copy_to_hram


.send_byte
    push hl
    ld  l,rBASE_VAL
    call _VRAM+.send_generic_byte
    pop hl
    ret
    
.send_check_byte
    push hl
    ld  l,rCHECK_VAL
    call _VRAM+.send_generic_byte
    pop hl
    ret

.send_generic_byte
    push bc
    ld  h,a
    call _VRAM+.send_nybble
    ld  b,a
    swap b
    call _VRAM+.send_nybble
    or a,b
    pop bc
    ret

.send_nybble
    swap h
    ld  a,h
    and a,$0F
    or  a,l
    ld  [rSB],a
    ld  a,rSLAVE_MODE
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
    and a,$0F
    ret
    
SECTION "HRAM_NO_BANK_SWITCHING",ROM0
hram_code_no_bank:
    ld  a,LCDCF_ON | LCDCF_BG8000 | LCDCF_BG9C00 | LCDCF_OBJ8 | LCDCF_OBJOFF | LCDCF_WINOFF | LCDCF_BGON
    ld  [rLCDC],a
    ld  hl,$0000
    
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
    ld  b,a
    jr  z,.main_loop
    call $FF80+.wait_VRAM_accessible-hram_code
    xor a
    ld  [rLCDC],a
    jp  _VRAM+start.prepare_ROM_dumper
    
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

SECTION "Graphics",ROM0[$800]
INCBIN "ui_graphics.bin"
