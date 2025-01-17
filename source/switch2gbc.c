// SPDX-License-Identifier: MIT
//
// Copyright (c) 2014, 2020 Antonio Ni�o D�az (AntonioND)

#include <stdio.h>

#include <gba.h>

#include "payload_array.h"
#define VRAM_SIZE 0x1000

#define REG_VCOUNT *(vu16*)0x04000006
#define ALWAYS_INLINE __attribute__((always_inline)) static inline

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

void prepare_registers(void)
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

void simpleirq(void)
{
    REG_IME = 0;
    REG_IF = 0xFFFF;
    REG_IME = 1;
}

IWRAM_CODE void print_switching_info(void)
{
    consoleDemoInit();
    iprintf("Swap cartridges now!\n");
    iprintf("\n");
    iprintf("Waiting 10 seconds...\n");
}

IWRAM_CODE void delayed_switch2gbc(void)
{    
    REG_IME = 0;

    // Write payload to IWRAM
    uint8_t* iwram_8 = (uint32_t*)0x03000000;
    memset(iwram_8, 0, VRAM_SIZE*4);
    for (int i = 0; i < PAYLOAD_SIZE; i++)
    {
        iwram_8[i * 4] = gbc_payload[i];
    }

    // VBlank per second about 60
    //for (int i = 0; i < 60 * 10; i++)
    //{   
    //    while(REG_VCOUNT >= 160);   // wait till VDraw
    //    while(REG_VCOUNT < 160);    // wait till VBlank
    //}

    BG_PALETTE[0] = 0x0000;
    BG_PALETTE[1] = 0x7FFF;
    
    
    REG_IME = 0;
    REG_IE = 0;
    REG_IF = 0xFFFF;

    REG_IME = 0;
    
    // Write 0x0408 to DISPCNT = 0x0408: Mode 0, GBC mode enabled, BG2 enabled
    uint16_t* GBC_DISPCNT_VALUE = (uint16_t*)0x6007FFC;
    *GBC_DISPCNT_VALUE = 0x408;

    // GBC mode bit can only be modified from BIOS, like from inside CpuSet()
    // Copy 1 halfword, 16 bit mode
    SWI_CpuSet(GBC_DISPCNT_VALUE, (void *)(REG_BASE + 0), 1);
    
    // Normal boot, black screen with jingle
    //*(vu32*)0x4000800 = 0x0D000000 | 0x20;
    //SWI_Halt();

    // BIOS swapped boot, white screen  no jingle
    *(vu32*)0x4000800 = 0x0D000000 | 0x20 | 8;
    SWI_Halt();
}