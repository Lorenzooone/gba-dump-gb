#include <gba.h>
#include "save.h"

#define BASE_FLASH_CMD *(flash_access+0x5555) = 0xAA; *(flash_access+0x2AAA) = 0x55;
#define FLASH_WRITE_CMD BASE_FLASH_CMD *(flash_access+0x5555) = 0xA0;
#define FLASH_ERASE_CMD BASE_FLASH_CMD *(flash_access+0x5555) = 0x80; BASE_FLASH_CMD *(flash_access+0x5555) = 0x10;
#define FLASH_BANK_CMD BASE_FLASH_CMD *(flash_access+0x5555) = 0xB0;
#define FLASH_TERM_CMD *(flash_access+0x5555) = 0xF0;
#define MAX_FLASH_RETRIES 3
#define timeout 50000
#define BANK_SIZE 0x10000

IWRAM_CODE void sram_write(u8* data, int size) {
    vu8* sram_access = (vu8*)SRAM;
    for(int i = 0; i < size; i++)
        *(sram_access+i) = data[i];
}

IWRAM_CODE int is_sram_correct(u8* data, int size) {
    vu8* sram_access = (vu8*)SRAM;
    for(int i = 0; i < size; i++)
        if (*(sram_access+i) != data[i])
            return 0;
    if(size > BANK_SIZE)
        return 0;
    return 1;
}

IWRAM_CODE void flash_write(u8* data, int size, int has_banks) {
    vu8* flash_access = (vu8*)SRAM;
    int base_difference = 0;
    if(has_banks) {
        FLASH_BANK_CMD
        *(flash_access) = 0;
        base_difference = 0;
    }
    for(int i = 0; i < MAX_FLASH_RETRIES; i++) {
        FLASH_ERASE_CMD
        for(vu32 j = 0; j < (timeout*(has_banks ? 32 : 16)); j++);
        u8 failed = 0;
        for(int j = 0; j < size; j++) {
            if((j == BANK_SIZE) && has_banks) {
                FLASH_BANK_CMD
                *(flash_access) = 1;
                base_difference = BANK_SIZE;
            }
            if((*(flash_access + j - base_difference)) != 0xFF) {
                failed = 1;
                break;
            }
        }
        if(failed)
            FLASH_TERM_CMD
        else
            break;
    }
    if(has_banks) {
        FLASH_BANK_CMD
        *(flash_access) = 0;
        base_difference = 0;
    }
    for(int i = 0; i < size; i++) {
        if((i == BANK_SIZE) && has_banks) {
            FLASH_BANK_CMD
            *(flash_access) = 1;
            base_difference = BANK_SIZE;
        }
        for(int k = 0; k < MAX_FLASH_RETRIES; k++) {
            FLASH_WRITE_CMD
            *(flash_access+i-base_difference) = data[i];
            for(vu32 j = 0; (j < timeout) && ((*(flash_access+i-base_difference)) != data[i]); j++);
            if((*(flash_access+i-base_difference)) == data[i])
                break;
            FLASH_TERM_CMD
        }
    }
    if(has_banks) {
        FLASH_BANK_CMD
        *(flash_access) = 0;
        base_difference = 0;
    }
}

IWRAM_CODE int is_flash_correct(u8* data, int size, int has_banks) {
    vu8* flash_access = (vu8*)SRAM;
    int base_difference;
    if(has_banks) {
        FLASH_BANK_CMD
        *(flash_access) = 0;
        base_difference = 0;
    }
    for(int i = 0; i < size; i++) {
        if((i == BANK_SIZE) && has_banks) {
            FLASH_BANK_CMD
            *(flash_access) = 1;
            base_difference = BANK_SIZE;
        }
        if (*(flash_access+i-base_difference) != data[i]) {
            if(has_banks) {
                FLASH_BANK_CMD
                *(flash_access) = 0;
                base_difference = 0;
            }
            return 0;
        }
    }
    if(has_banks) {
        FLASH_BANK_CMD
        *(flash_access) = 0;
        base_difference = 0;
        if(size > (2*BANK_SIZE))
            return 0;
    }
    else if(size > BANK_SIZE)
        return 0;
    return 1;
}

void rom_write(u8* data, int size) {
    /*
    vu8* free_section_ptr = (vu8*)free_section;
    for(int i = 0; i < size; i++)
        *(free_section_ptr+i) = data[i];
    */
}

unsigned int get_rom_address() {
    /*
    return (unsigned int)free_section;
    */
    return 0x8000000;
}

int is_rom_correct(u8* data, int size) {
    /*
    vu8* free_section_ptr = (vu8*)free_section;
    for(int i = 0; i < size; i++)
        if (*(free_section_ptr+i) != data[i])
            return 0;
    */
    if(size > (2*BANK_SIZE))
        return 0;
    return 1;
}