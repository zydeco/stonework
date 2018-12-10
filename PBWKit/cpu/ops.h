//
//  ops.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 16/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#ifndef ops_h
#define ops_h

#include <assert.h>

// register fields

#define R cpu->reg
#define APSR_N ((cpu->reg[REG_APSR] & 0x80000000) >> 31)
#define APSR_Z ((cpu->reg[REG_APSR] & 0x40000000) >> 30)
#define APSR_C ((cpu->reg[REG_APSR] & 0x20000000) >> 29)
#define APSR_V ((cpu->reg[REG_APSR] & 0x10000000) >> 28)
#define APSR_Q ((cpu->reg[REG_APSR] & 0x08000000) >> 27)
#define APSR_GE ((cpu->reg[REG_APSR] & 0x000F0000) >> 16)

#define ASSERT_U32(_value) _Static_assert(_Generic(_value, uint32_t: 1, default: 0), "required uint32_t");
#define SetAPSR_NZ(_value) ASSERT_U32(_value); cpu->reg[REG_APSR] = (_value & 0x80000000) | ((_value == 0) << 30) | (cpu->reg[REG_APSR] & 0x3FFFFFFF);
#define SetAPSR_NZC(_value,_c) ASSERT_U32(_value); cpu->reg[REG_APSR] = (_value & 0x80000000) | ((_value == 0) << 30) | ((_c) << 29) | (cpu->reg[REG_APSR] & 0x1FFFFFFF);
#define SetAPSR_NZCV(_value,_c,_v) ASSERT_U32(_value); cpu->reg[REG_APSR] = (_value & 0x80000000) | ((_value == 0) << 30) | ((_c) << 29) | ((_v) << 28) | (cpu->reg[REG_APSR] & 0x0FFFFFFF)
#define SetAPSR_NZCVQ(_value,_c,_v,_q) ASSERT_U32(_value); cpu->reg[REG_APSR] = (_value & 0x80000000) | ((_value == 0) << 30) | ((_c) << 29) | ((_v) << 28) | ((_q) << 27) | (cpu->reg[REG_APSR] & 0x07FFFFFF)
#define SetAPSR_Q(_q) cpu->reg[REG_APSR] = ((_q) << 27) | (cpu->reg[REG_APSR] & 0xF7FFFFFF)
#define SetAPSR_GE(_ge) cpu->reg[REG_APSR] = ((_ge) << 16) | (cpu->reg[REG_APSR] & 0xFFF0FFFF)

#define CPU_BREAK(error, ...) { cpu->running = 0; cpu->err = PBW_ERR_ ## error; R[REG_PC] = pc; return __VA_ARGS__; };

#define ITSTATE (((cpu->reg[REG_EPSR] & 0x6000000) >> 25) | ((cpu->reg[REG_EPSR] & 0xFC00) >> 8))
#define SetITSTATE(value) SetITSTATEImpl(cpu, value)
static inline void SetITSTATEImpl(pbw_cpu cpu, int val) {
    uint32_t encoded_itstate = ((val & 0x03) << 25) | ((val & 0xFC) << 8);
    cpu->reg[REG_EPSR] = (cpu->reg[REG_EPSR] & 0xF9FF03FFUL) | encoded_itstate;
}

#define CurrentCond() CurrentCondImpl(cpu, ins, pc)
static inline int CurrentCondImpl(pbw_cpu cpu, uint32_t ins, uint32_t pc) {
    if ((ins & 0xF800D000) == 0xF0008000) {
        // B T3
        return (ins & 0x3C00000) >> 22;
    } else if ((ins & 0xF000) == 0xD000) {
        // B T1
        return (ins & 0x0F00) >> 8;
    } else if (cpu->reg[REG_EPSR] & EPSR_MASK_IT) {
        // ITSTATE
        return (cpu->reg[REG_EPSR] & 0xF000) >> 12;
    } else {
        // ITSTATE is zero
        return 0xe;
    }
}

#define InITBlock() InITBlockImpl(cpu)
static inline int InITBlockImpl(pbw_cpu cpu) {
    return (ITSTATE & 0xF) != 0;
}

#define ConditionPassed() ConditionPassedImpl(cpu, ins, pc)
static inline int ConditionPassedImpl(pbw_cpu cpu, uint32_t ins, uint32_t pc) {
    int result = 0;
    int cond = CurrentCond();
    switch (cond >> 1) {
        case 0b000: result = (APSR_Z == 1); break; // EQ or NE
        case 0b001: result = (APSR_C == 1); break; // CS or CC
        case 0b010: result = (APSR_N == 1); break; // MI or PL
        case 0b011: result = (APSR_V == 1); break; // VS or VC
        case 0b100: result = ((APSR_C == 1) && (APSR_Z == 0)); break; // HI or LS
        case 0b101: result = (APSR_N == APSR_V); break; // GE or LT
        case 0b110: result = ((APSR_N == APSR_V) && APSR_Z == 0); break; // GT or LE
        case 0b111: result = 1; break; // AL
    }
    
    if ((cond & 0x1) && (cond != 0xF)) {
        result = !result;
    }
#ifdef PRINT_STATE
    if (InITBlock() && !result) {
        printf("(condition not passed)\n");
    }
#endif
    return result;
}

#define ITAdvance() ITAdvanceImpl(cpu)
static inline void ITAdvanceImpl(pbw_cpu cpu) {
    if ((ITSTATE & 0x7) == 0) {
        SetITSTATE(0);
    } else {
        SetITSTATE((ITSTATE & 0xE0) | ((ITSTATE & 0x0F) << 1));
    }
}

#define LastInITBlock() LastInITBlockImpl(cpu)
static inline int LastInITBlockImpl(pbw_cpu cpu) {
    return(ITSTATE & 0xF) == 0x8;
}

static inline uint32_t BitCount(uint32_t v) {
    v = v - ((v >> 1) & 0x55555555); // reuse input as temporary
    v = (v & 0x33333333) + ((v >> 2) & 0x33333333); // temp
    return ((v + (v >> 4) & 0xF0F0F0F) * 0x1010101) >> 24; // count
}

static inline int16_t SignExtend8to16(uint8_t x) {
    return (x & 0x80) ? 0xff00 | (uint16_t)x : x;
}

static inline int32_t SignExtend8to32(uint8_t x) {
    return (x & 0x80) ? 0xffffff00 | (uint32_t)x : x;
}

static inline int32_t SignExtend16to32(uint16_t x) {
    return (x & 0x8000) ? 0xffff0000 | (uint32_t)x : x;
}


#endif /* ops_h */
