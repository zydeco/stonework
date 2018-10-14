//
//  alu.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 17/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#ifndef alu_h
#define alu_h

#include <assert.h>

enum SRType {
    SRType_LSL = 0,
    SRType_LSR = 1,
    SRType_ASR = 2,
    SRType_ROR_RRX = 3
};

static inline unsigned int DecodeImmShift(unsigned int type, unsigned int imm5) {
    assert(type <= 3);
    switch(type) {
        case 0: return imm5; // LSL
        case 1: return imm5 ?: 32; // LSR
        case 2: return imm5 ?: 32; // ASR
        case 3: return imm5 ?: 1; // ROR or RRX
    }
    return 0;
}

_Static_assert(-1 >> 1 == -1, "Signed right shift is arithmetic");
_Static_assert(((int32_t)0x80000000) == -2147483648, "Cast unsigned to signed");
_Static_assert(((uint32_t)0xFFFFFFFF) + 3 == 2, "Unsigned overflow");

static inline uint32_t LSL(uint32_t value, uint32_t amount) {
    return value << amount;
}

static inline uint32_t LSL_Carry(uint32_t value, uint32_t amount) {
    return (value >> (32 - amount)) & 1;
}

static inline uint32_t LSR(uint32_t value, uint32_t amount) {
    return value >> amount;
}

static inline uint32_t LSR_Carry(uint32_t value, uint32_t amount) {
    return (value & (1 << (amount - 1)));
}

static inline uint32_t ASR(uint32_t value, uint32_t amount) {
    return ((int32_t)value) >> amount;
}

#define ASR_Carry LSR_Carry

static inline uint32_t ROR(uint32_t value, uint32_t amount) {
    amount &= 31;
    return (value >> amount) | (value << (32 - amount));
}

static inline uint32_t ROR_Carry(uint32_t value, uint32_t amount) {
    amount &= 31;
    return (value >> (amount - 1)) & 1;
}

static inline uint32_t RRX(uint32_t value, uint32_t carry_in) {
    carry_in &= 1;
    return (value >> 1) | (carry_in << 31);
}

static inline uint32_t RRX_Carry(uint32_t value, uint32_t carry_in) {
    return value & 1;
}

uint32_t pbw_cpu_alu_shift(pbw_cpu cpu, uint32_t value, uint32_t type, uint32_t imm5, uint32_t carry_in, uint32_t setflags);

static inline uint32_t ShiftCarry(uint32_t value, enum SRType type, uint32_t amount, uint32_t carry_in) {
    if (amount == 0 && type != SRType_ROR_RRX) {
        return carry_in;
    } else switch (type) {
        case SRType_LSL: return LSL_Carry(value, amount);
        case SRType_LSR: return LSR_Carry(value, amount);
        case SRType_ASR: return ASR_Carry(value, amount);
        case SRType_ROR_RRX: return amount ? ROR_Carry(value, amount) : RRX_Carry(value, carry_in);
    }
}

struct AddResult {
    unsigned int carry: 1;
    unsigned int overflow: 1;
    uint32_t value;
};

static inline struct AddResult AddWithCarry(uint32_t x, uint32_t y, uint32_t carry_in) {
    struct AddResult result = {0, 0, 0};
    uint64_t unsigned_sum = (uint64_t)x + (uint64_t)y + (uint64_t)carry_in;
    int64_t signed_sum = (int64_t)x + (int64_t)y + (uint64_t)carry_in;
    result.value = unsigned_sum & 0xFFFFFFFF;
    result.carry = result.value == unsigned_sum;
    result.overflow = (int64_t)((int32_t)result.value) == signed_sum;
    return result;
}

uint32_t pbw_cpu_alu_add(pbw_cpu cpu, uint32_t x, uint32_t y, uint32_t carry_in, uint32_t setflags);

#define Align(x,y) ((x) & ~(y-1))

#define ENC_ThumbExpandImm(v1) uint32_t v1 = ThumbExpandImm(ins)
static inline uint32_t ThumbExpandImm(uint32_t ins) {
    if (ins & 0x4004000) {
        // shifted 8-bit value
        uint32_t shift = ((ins & 0x4000000) >> 22) | // i
        ((ins & 0x7000) >> 11) | // imm3
        ((ins & 0x80) >> 7); // a
        uint32_t value = (0x80 | (ins & 0x7f)) << (32 - shift);
        return value;
    } else {
        uint32_t value = (ins & 0xff);
        switch(ins & 0x3000) {
            case 0x0000:
                return value;
            case 0x1000:
                return (value << 16) | value;
            case 0x2000:
                return (value << 24) | (value << 8);
            case 0x3000:
                return (value << 24) | (value << 16) | (value << 8) | value;
        }
    }
    __builtin_unreachable();
}

#define ThumbExpandImmShouldCarry(ins) (ins & 0x4004000)

#define ENC_ThumbExpandImm_C(v1,vc) uint32_t v1 = ThumbExpandImm(ins); uint32_t vc = ThumbExpandImmShouldCarry(ins) ? (v1 >> 31) : APSR_C;

#define ENC_ThumbImm12(v1) uint32_t v1 = ((ins & 0x4000000) >> 15) | ((ins & 0x7000) >> 4) | (ins & 0xff);
#define ENC_ThumbImm16(v1) uint32_t v1 = ((ins & 0xf0000) >> 4) | ((ins & 0x4000000) >> 15) | ((ins & 0x7000) >> 4) | (ins & 0xff);

#endif /* alu_h */
