    INCLUDE "hardware.inc"             ; system defines

rROM_TRANSFER EQU $1
rSRAM_TRANSFER EQU $2
rSLAVE_MODE EQU $82
rOK  EQU $1
rFAIL EQU $0
rBASE_VAL EQU $10
rCHECK_VAL EQU $40
rROM_BANK_SIZE EQU $40
rSRAM_SUB_BANK_SIZE EQU $8
rSRAM_MBC2_BANK_SIZE EQU $2
CART_RUMBLE_ENABLE EQU $8

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
    jp  z,_VRAM+.prepare_SRAM_dumper
    push bc
    
.send_start_rom
    ld  a,rROM_TRANSFER
    call _VRAM+.send_byte              ; init transfer, ROM
    ld  a,[$0148]
    ld  h,a

.check_mbc1_rom
    xor a
    ld  [$FF82],a                      ; which type of function one should use
    ld  a,[$0147]
    ld  b,a
    cp  a,CART_ROM_MBC1
    jr  c,.transfer_size_rom
    ld  a,CART_ROM_MBC1_RAM_BAT
    cp  a,b
    jr  c,.check_mbc5_rom
    ld  a,$1                           ; MBC1 has separate ROM addressing bits
    ld  [$FF82],a
    jr  .transfer_size_rom
    
.check_mbc5_rom
    ld  a,b
    cp  a,CART_ROM_MBC5
    jr  c,.transfer_size_rom
    ld  a,CART_ROM_MBC5_RUM_RAM_BAT
    cp  a,b
    jr  c,.transfer_size_rom
    ld  a,$2                           ; MBC5 can access up to 0x1E0 different banks
    ld  [$FF82],a

.transfer_size_rom
    ld  b,$00
    ld  a,h
    and a,$1F
    ld  c,a
    push hl
    ld  hl,_VRAM+romSizes
    add hl,bc
    ld  a,[hl]
    pop hl
    ld  b,a
    ld  c,rOK
    ld  a,h
    call _VRAM+.send_byte              ; send ROM size
    cp  a,rROM_TRANSFER
    jr  z,.transfer_first_rom
    ld  c,rFAIL
.transfer_first_rom
    ld  a,h
    call _VRAM+.send_byte              ; get ROM size
    cp  a,h
    jr  z,.transfer_second_rom
    ld  c,rFAIL
.transfer_second_rom
    ld  h,c
    ld  a,c
    call _VRAM+.send_check_byte        ; check success
    ld  a,c
    cp  a,rFAIL
    jr  z,.send_start_rom
    xor a
    ld  [$FF80],a
    ld  [$FF81],a
    ld  de,$0000
.ROM_banks_continue_transfer
    call _VRAM+.transfer_4_ROM_banks
    ld  a,b
    cp  a,$00
    jr  nz,.ROM_banks_continue_transfer
    pop bc

.prepare_SRAM_dumper
    ld  a,b
    and a,PADF_B|PADF_START
    jp  z,_VRAM+.SRAM_banks_transfer_end

.send_start_sram
    ld  a,rSRAM_TRANSFER
    call _VRAM+.send_byte              ; init transfer, SRAM
    ld  a,[$0149]
    ld  h,a

.check_mbc1_sram
    xor a
    ld  [$FF82],a                      ; which type of function one should use
    ld  a,[$0147]
    ld  b,a
    cp  a,CART_ROM_MBC1
    jr  c,.transfer_size_sram
    ld  a,CART_ROM_MBC1_RAM_BAT
    cp  a,b
    jr  c,.check_mbc5_rumble_sram
    ld  a,$1                           ; enable SRAM advanced banking mode
    ld  [$6000],a
    jr  .transfer_size_sram

.check_mbc2_sram
    ld  a,b
    cp  a,CART_ROM_MBC2
    jr  c,.transfer_size_sram
    ld  a,CART_ROM_MBC2_BAT
    cp  a,b
    jr  c,.check_mbc5_rumble_sram
    ld  a,$1
    ld  h,a                            ; MBC2 carts have 0x200 SRAM bytes of 4 bits
    ld  [$FF82],a
    jr  .transfer_size_sram
    
.check_mbc5_rumble_sram
    ld  a,b
    cp  a,CART_ROM_MBC5_RUM
    jr  c,.transfer_size_sram
    ld  a,CART_ROM_MBC5_RUM_RAM_BAT
    cp  a,b
    jr  c,.transfer_size_sram
    ld  a,$2                           ; Rumble breaks the SRAM addressing bits in half
    ld  [$FF82],a

.transfer_size_sram
    ld  b,$00
    ld  a,h
    and a,$07
    ld  c,a
    push hl
    ld  hl,_VRAM+sramSizes
    add hl,bc
    ld  a,[hl]
    pop hl
    ld  b,a
    ld  c,rOK
    ld  a,h
    call _VRAM+.send_byte              ; send SRAM size
    cp  a,rSRAM_TRANSFER
    jr  z,.transfer_first_sram
    ld  c,rFAIL
.transfer_first_sram
    ld  a,h
    call _VRAM+.send_byte              ; get SRAM size
    cp  a,h
    jr  z,.transfer_second_sram
    ld  c,rFAIL
.transfer_second_sram
    ld  h,c
    ld  a,c
    call _VRAM+.send_check_byte        ; check success
    ld  a,c
    cp  a,rFAIL
    jr  z,.send_start_sram
    xor a
    ld  [$FF80],a
    ld  [$FF81],a
    ld  a,b
    cp  a,$FF
    jr  z,.SRAM_banks_transfer_end
    ld  e,$00
.SRAM_banks_continue_transfer
    call _VRAM+.transfer_4_SRAM_sub_banks
    ld  a,b
    cp  a,$00
    jr  nz,.SRAM_banks_continue_transfer
.SRAM_banks_transfer_end

    jp  _VRAM+.copy_to_hram

.transfer_4_SRAM_sub_banks
    ld  c,$4
    ld  a,[$FF82]
    cp  a,$00
    jr  z,.transfer_4_SRAM_sub_banks_simple
    cp  a,$02
    jr  z,.transfer_4_SRAM_sub_banks_mbc5_rumble
    jr  .transfer_SRAM_sub_bank_mbc2

.transfer_4_SRAM_sub_banks_simple
    ld  a,[$FF80]
    ld  [$4000],a
    inc a
    ld  [$FF80],a
    ld  d,$A0
    ld  a,CART_RAM_ENABLE
    ld  [$0000],a
.transfer_4_SRAM_sub_banks_simple_loop
    call _VRAM+.transfer_SRAM_sub_bank
    ld  a,b
    cp  a,$00
    jr  z,.end_SRAM_transfer_simple
    dec c
    jr  nz,.transfer_4_SRAM_sub_banks_simple_loop
    dec b
.end_SRAM_transfer_simple
    xor a
    ld  [$0000],a                      ; disable cart SRAM to avoid damage
    ret
    
.transfer_SRAM_sub_bank_mbc2
    ld  d,$A0
    ld  a,CART_RAM_ENABLE
    ld  [$0000],a
    call _VRAM+.transfer_SRAM_MBC2_bank
    ld  b,$00
    xor a
    ld  [$0000],a                      ; disable cart SRAM to avoid damage
    ret
    
.transfer_4_SRAM_sub_banks_mbc5_rumble
    ld  a,[$FF80]
    ld  d,a
    ld  a,[$FF81]
    or  a,d
    ld  [$4000],a
    ld  a,[$FF80]
    inc a
    cp  a,CART_RUMBLE_ENABLE
    jr  nz,.save_next_sram_rumble_bank
    ld  a,[$FF81]
    add a,CART_RUMBLE_ENABLE*2
    ld  [$FF81],a
    xor a
.save_next_sram_rumble_bank
    ld  [$FF80],a
    ld  d,$A0
    ld  a,CART_RAM_ENABLE
    ld  [$0000],a
.transfer_4_SRAM_sub_banks_mbc5_rumble_loop
    call _VRAM+.transfer_SRAM_sub_bank
    ld  a,b
    cp  a,$00
    jr  z,.end_transfer_4_SRAM_sub_banks_mbc5_rumble
    dec c
    jr  nz,.transfer_4_SRAM_sub_banks_mbc5_rumble_loop
    dec b
.end_transfer_4_SRAM_sub_banks_mbc5_rumble
    xor a
    ld  [$0000],a                      ; disable cart SRAM to avoid damage
    ret
    
.transfer_4_ROM_banks
    ld  c,$2
    ld  a,[$FF82]
    cp  a,$00
    jr  z,.transfer_4_ROM_banks_simple
    cp  a,$02
    jr  z,.transfer_4_ROM_banks_mbc5
    jr  .transfer_4_ROM_banks_mbc1

.transfer_4_ROM_banks_simple
    ld  a,[$FF80]
    ld  [$2100],a
    inc a
    ld  [$FF80],a
    call _VRAM+.transfer_ROM_bank
    ld  a,[$FF80]
    ld  [$2100],a
    inc a
    ld  [$FF80],a
    ld  d,$40
    call _VRAM+.transfer_ROM_bank
    ld  d,$40
    ld  a,b
    cp  a,$00
    jr  z,.end_ROM_transfer_simple
    dec c
    jr  nz,.transfer_4_ROM_banks_simple
    dec b
.end_ROM_transfer_simple
    ret
    
.transfer_4_ROM_banks_mbc5
    ld  a,[$FF80]
    ld  [$2100],a
    inc a
    ld  [$FF80],a
    ld  a,[$FF81]
    ld  [$3100],a
    call _VRAM+.transfer_ROM_bank
    ld  a,[$FF80]
    ld  [$2100],a
    inc a
    ld  [$FF80],a
    ld  a,[$FF81]
    ld  [$3100],a
    ld  a,[$FF80]
    cp  a,$00
    jr  nz,.keep_transfering_mbc5
    ld  a,[$FF81]
    inc a
    ld  [$FF81],a
    
.keep_transfering_mbc5
    ld  d,$40
    call _VRAM+.transfer_ROM_bank
    ld  d,$40
    ld  a,b
    cp  a,$00
    jr  z,.end_ROM_transfer_mbc5
    dec c
    jr  nz,.transfer_4_ROM_banks_mbc5
    dec b
.end_ROM_transfer_mbc5
    ret
    
.transfer_4_ROM_banks_mbc1
    ld  a,[$FF80]
    ld  [$2100],a
    inc a
    ld  [$FF80],a
    ld  a,[$FF81]
    ld  [$4000],a
    call _VRAM+.transfer_ROM_bank
    ld  a,[$FF80]
    ld  [$2100],a
    inc a
    ld  [$FF80],a
    ld  a,[$FF81]
    ld  [$4000],a
    ld  a,[$FF80]
    cp  a,$20
    jr  nz,.keep_transfering_mbc1
    xor a
    ld  [$FF80],a
    ld  a,[$FF81]
    inc a
    ld  [$FF81],a
    
.keep_transfering_mbc1
    ld  d,$40
    call _VRAM+.transfer_ROM_bank
    ld  d,$40
    ld  a,[$FF80]
    cp  a,$00
    jr  nz,.past_advanced_mode
    ld  d,$00
    inc a
    ld  [$6000],a
.past_advanced_mode
    ld  a,b
    cp  a,$00
    jr  z,.end_ROM_transfer_mbc1
    dec c
    jr  nz,.transfer_4_ROM_banks_mbc1
    dec b
.end_ROM_transfer_mbc1
    ret

.transfer_ROM_bank
    push bc
    ld  l,rROM_BANK_SIZE
    call _VRAM+.transfer_bank
    pop bc
    ret

.transfer_SRAM_sub_bank
    push bc
    ld  l,rSRAM_SUB_BANK_SIZE
    call _VRAM+.transfer_bank
    pop bc
    ret
    
.transfer_SRAM_MBC2_bank
    push bc
    ld  l,rSRAM_MBC2_BANK_SIZE
    call _VRAM+.transfer_bank
    pop bc
    ret

.transfer_bank
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
    dec l
    jr  nz,.transfer_group
.success_bank
    ret

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

    SECTION "ROM_SIZES",ROM0
romSizes:
DB $00,$01,$02,$04,$08,$10,$20,$40,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$12,$14,$18

    SECTION "SRAM_SIZES",ROM0
sramSizes:
DB $FF,$00,$01,$04,$10,$08

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
