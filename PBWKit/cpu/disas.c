//
//  disas.c
//  Stonework
//
//  Created by Jesús A. Álvarez on 15/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#include "cpu_priv.h"

#define disas(format, ...) return snprintf(buf, size, format, __VA_ARGS__)
int pbw_cpu_disas_thumb(uint32_t ins, char *buf, size_t size, uint8_t itstate) {
    uint32_t opcode = (ins & 0xFC00) >> 10;
    if ((opcode & 0x30) == 0) {
        // Shift (immediate), add, subtract, move, and compare on page A5-157
    }
    disas("THUMB %04X", ins);
}

int pbw_cpu_disas_thumb2(uint32_t ins, char *buf, size_t size, uint8_t itstate) {
    disas("THUMB2 %08X", ins);
}

int pbw_cpu_disas(uint32_t ins, char *buf, size_t size, uint8_t itstate) {
    if (INSTRUCTION_SIZE(ins) == 2) {
        return pbw_cpu_disas_thumb(ins, buf, size, itstate);
    } else {
        return pbw_cpu_disas_thumb2(ins, buf, size, itstate);
    }
}
