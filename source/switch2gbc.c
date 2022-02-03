// SPDX-License-Identifier: MIT
//
// Copyright (c) 2014, 2020 Antonio Niño Díaz (AntonioND)

#include <stdio.h>

#include <gba.h>

#define ALWAYS_INLINE __attribute__((always_inline)) static inline

const uint8_t gbc_payload[0x42] = {0xAF, 0xE0, 0x40, 0x21, 0x17, 0x80, 0x0E, 0x80, 0x2A, 0xE2, 0x0C, 0x20, 0xFB, 0x21, 0x01, 0x01, 0x3E, 0x11, 0xE0, 0x50, 0xC3, 0x80, 0xFF, 0x3E, 0x80, 0xE0, 0x40, 0x06, 0x0C, 0xAF, 0xE0, 0x0F, 0x3C, 0xE0, 0xFF, 0x18, 0x15, 0x05, 0x20, 0xF5, 0x3E, 0xFF, 0xE0, 0x24, 0xE0, 0x25, 0xE0, 0x26, 0x00, 0x7E, 0xE0, 0x12, 0xE0, 0x13, 0xE0, 0x14, 0x18, 0xE1, 0xF0, 0x0F, 0xE6, 0x01, 0x28, 0xFA, 0x18, 0xE3};

extern void RAM_stub(void);

ALWAYS_INLINE void SWI_Halt(void)
{
    asm volatile(
        "swi 0x02" :::
        "r0", "r1", "r2", "r3", "memory"
    );
}

ALWAYS_INLINE void SWI_CpuSet(const void *src, void *dst, uint32_t len_mode)
{
    register uint32_t src_ asm("r0") = (uint32_t)src;
    register uint32_t dst_ asm("r1") = (uint32_t)dst;
    register uint32_t len_mode_ asm("r2") = len_mode;

    asm volatile(
        "swi 0x0B" ::
        "r"(src_), "r"(dst_), "r"(len_mode_) :
        "r3", "memory"
    );
}

// BSS is by default in IWRAM
uint16_t GBC_DISPCNT_VALUE;

IWRAM_CODE void prepare_registers(void)
{
    // Reset all I/O to default values

    *((u16*)0x04000002) = 0; // GREENSWAP

    REG_BG0CNT = 0; REG_BG1CNT = 0; REG_BG3CNT = 0;
    REG_BG2PA = 0x0100; REG_BG2PB = 0x0000; REG_BG2PC = 0x0000; REG_BG2PD = 0x0100;
    REG_BG3PA = 0x0100; REG_BG3PB = 0x0000; REG_BG3PC = 0x0000; REG_BG3PD = 0x0100;
    REG_BG3X = 0; REG_BG3Y = 0;

    REG_WIN0H = 0; REG_WIN0V = 0; REG_WIN1H = 0; REG_WIN1V = 0;
    REG_WININ = 0; REG_WINOUT = 0;

    REG_MOSAIC = 0; REG_BLDCNT = 0; REG_BLDALPHA = 0; REG_BLDY = 0;

    REG_VCOUNT = 0;

    REG_BG0HOFS = 0; REG_BG0VOFS = 0; REG_BG1HOFS = 0; REG_BG1VOFS = 0;
    REG_BG2HOFS = 0; REG_BG2VOFS = 0; REG_BG3HOFS = 0; REG_BG3VOFS = 0;

    REG_SOUND1CNT_L = 0; REG_SOUND1CNT_H = 0; REG_SOUND1CNT_X = 0;
    REG_SOUND2CNT_L = 0; REG_SOUND2CNT_H = 0;
    REG_SOUND3CNT_L = 0; REG_SOUND3CNT_H = 0; REG_SOUND3CNT_X = 0;
    REG_SOUND4CNT_L = 0; REG_SOUND4CNT_H = 0;

    REG_SOUNDCNT_L = 0; REG_SOUNDCNT_X = 0;

    REG_DMA0SAD = 0; REG_DMA0DAD = 0; REG_DMA0CNT = 0;
    REG_DMA1SAD = 0; REG_DMA1DAD = 0; REG_DMA1CNT = 0;
    REG_DMA2SAD = 0; REG_DMA2DAD = 0; REG_DMA2CNT = 0;
    REG_DMA3SAD = 0; REG_DMA3DAD = 0; REG_DMA3CNT = 0;

    REG_TM0CNT = 0; REG_TM1CNT = 0; REG_TM2CNT = 0; REG_TM3CNT = 0;

    REG_KEYCNT = 0;

    //REG_WAITCNT = ???

    // Do BIOS configuration...

    BG_PALETTE[0] = 0x0000;
    BG_PALETTE[1] = 0x7FFF;

    REG_BG2CNT = 0x4180;
    REG_BG2X = 0xFFFFD800; // -40.0
    REG_BG2Y = 0xFFFFF800; // -8.0

    REG_SOUNDCNT_H = 0x88C2;
    REG_SOUNDBIAS = 0xC200; // 6 bit, 262.144kHz
}

IWRAM_CODE void switch2gbc(void)
{
    REG_IME = 0;
    
    // Write 0x0408 to DISPCNT = 0x0408: Mode 0, GBC mode enabled, BG2 enabled
    GBC_DISPCNT_VALUE = 0x0408;

    // GBC mode bit can only be modified from BIOS, like from inside CpuSet()
    // Copy 1 halfword, 16 bit mode
    SWI_CpuSet(&GBC_DISPCNT_VALUE, (void *)(REG_BASE + 0), 1);
    
    // Normal boot, black screen with jingle
    //*(vu32*)0x4000800 = 0x0D000000 | 0x20;
    //SWI_Halt();

    // BIOS swapped boot, white screen  no jingle
    *(vu32*)0x4000800 = 0x0D000000 | 0x20 | 8;
    SWI_Halt();
}

IWRAM_CODE void simpleirq(void)
{
    REG_IME = 0;
    REG_IF = 0xFFFF;
    REG_IME = 1;
}

IWRAM_CODE void delayed_switch2gbc(void)
{
    
    REG_IME = 0;

    // Write payload to IWRAM
    uint8_t* iwram_8 = (uint32_t*)0x03000000;
    memset(iwram_8, 0, 0x42*4);
    for (int i = 0; i < 0x42; i++)
    {
        iwram_8[i * 4] = gbc_payload[i];
    }

    BG_PALETTE[0] = 0x0000;
    BG_PALETTE[1] = 0x7FFF;
    
    
    REG_IME = 0;
    REG_IE = 0;
    REG_IF = 0xFFFF;

    switch2gbc();
}