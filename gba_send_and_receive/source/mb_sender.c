// SPDX-License-Identifier: MIT
//
// Copyright (c) 2020 Antonio Niño Díaz (AntonioND)

#include <stdio.h>
#include <string.h>

#include <gba.h>

#include "multiboot_handler.h"
#include "sio.h"
#include "gba_payload_array.h"

// --------------------------------------------------------------------

#define PACKED __attribute__((packed))
#define ALWAYS_INLINE __attribute__((always_inline)) static inline
#define NORMAL_BYTE 0x10
#define CHECK_BYTE 0x40
#define VCOUNT_TIMEOUT 28

int read_gb_dump_val(int data) {
    u8 received[2], envelope[2];
    
    for(int i = 0; i < 2; i++) {
        received[i] = timed_sio_normal_master((data & (0xF0 >> (i * 4))) >> (4 - (i * 4)), SIO_8, VCOUNT_TIMEOUT);
        envelope[i] = received[i] & 0xF0;
        received[i] = (received[i] & 0xF) << (4 - (i * 4));
        
        if ((envelope[i] != NORMAL_BYTE) && (envelope[i] != CHECK_BYTE))
            return -1;
    }
    
    if (envelope[1] != envelope[0]) {
        timed_sio_normal_master(0xFF, SIO_8, VCOUNT_TIMEOUT);
        return -1;
    }
    
    return received[0] | received[1];
}

void load_menu(void)
{
    iprintf("\x1b[2J");
    REG_DISPCNT = MODE_0 | BG0_ON;

    BG_PALETTE[0] = RGB5(0, 0, 0);
    BG_PALETTE[16 * 15 + 1] = RGB5(0, 0, 31);
}
// --------------------------------------------------------------------

int main(void)
{
    irqInit();
    irqEnable(IRQ_VBLANK);

    consoleDemoInit();
    
    scanKeys();
    while (!(keysDown() & KEY_START)) {scanKeys();}
    
    if (multiboot_normal((u16*)payload, (u16*)(payload + PAYLOAD_SIZE)) == MB_SUCCESS)
    {
        scanKeys();
        while (!(keysDown() & KEY_START)) {scanKeys();}
        
        init_sio_normal(SIO_MASTER, SIO_8);
        int val = 0;
        while(1) {
            val = read_gb_dump_val(val);
            iprintf("Read val: %d\n", val);
        }
        
    }
    return 0;
}
