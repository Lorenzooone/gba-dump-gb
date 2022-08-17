// SPDX-License-Identifier: MIT
//
// Copyright (c) 2020 Antonio Niño Díaz (AntonioND)

#include <stdio.h>
#include <string.h>

#include <gba.h>

#include "multiboot_handler.h"
#include "gba_payload_array.h"

// --------------------------------------------------------------------

#define PACKED __attribute__((packed))
#define ALWAYS_INLINE __attribute__((always_inline)) static inline

void load_menu(void)
{
    iprintf("\x1b[2J");
    REG_DISPCNT = MODE_0 | BG0_ON;

    BG_PALETTE[0] = RGB5(0, 0, 0);
    BG_PALETTE[16 * 15 + 1] = RGB5(0, 0, 31);
}

// First listed procedure
int sio_normal_slave(int data) {    
    // - Initialize data which is to be sent to master.
    REG_SIODATA32 = data;
    
    // - Set Start=0 and SO=0 (SO=LOW indicates that slave is (almost) ready).
    REG_SIOCNT &= ~(SIO_START | SIO_SO_HIGH);
    // - Set Start=1 and SO=1 (SO=HIGH indicates not ready, applied after transfer).
    //   (Expl. Old SO=LOW kept output until 1st clock bit received).
    //   (Expl. New SO=HIGH is automatically output at transfer completion).
    REG_SIOCNT |= SIO_START | SIO_SO_HIGH;
    // - Set SO to LOW to indicate that master may start now.
    REG_SIOCNT &= ~SIO_SO_HIGH;
    // - Wait for IRQ (or for Start bit to become zero). (Check timeout here!)
    while (REG_SIOCNT & SIO_START);
    
    //Stop next transfer
    REG_SIOCNT |= SIO_SO_HIGH;
    
    // - Process received data.
    return REG_SIODATA32;
}

int sio_normal_master(int data) {
    REG_SIODATA32 = data;
    
    // - Wait for SI to become LOW (slave ready). (Check timeout here!)
    while (REG_SIOCNT & SIO_RDY);
    // - Set Start flag.
    REG_SIOCNT |= SIO_START;
    // - Wait for IRQ (or for Start bit to become zero).
    while (REG_SIOCNT & SIO_START);
    
    return REG_SIODATA32;
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
    }
    return 0;
}
