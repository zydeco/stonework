//
//  exec.c
//  Stonework
//
//  Created by Jesús A. Álvarez on 15/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#include "cpu_priv.h"
#include "ops.h"
#include "alu.h"
#include "decode.h"

uint32_t pbw_cpu_get_next_instruction(pbw_cpu cpu) {
    uint32_t pc = cpu->reg[REG_PC] & ~1;
    uint32_t ins = pbw_cpu_mem_read(cpu, pc, PBW_MEM_EXEC, PBW_MEM_HALFWORD);
    if (((ins & 0xE000) == 0xE000) && (ins & 0x1800)) {
        // 32-bit instruction
        ins = (ins << 16) | pbw_cpu_mem_read(cpu, pc + 2, PBW_MEM_EXEC, PBW_MEM_HALFWORD);
        cpu->reg[REG_PC] += 4;
    } else {
        cpu->reg[REG_PC] += 2;
    }
    return ins;
}

#ifdef PRINT_STATE
void print_regs(pbw_cpu cpu) {
    printf("R0=%08x:", R[0]);
    printf("%08x:", R[1]);
    printf("%08x:", R[2]);
    printf("%08x:", R[3]);
    printf("%08x:", R[4]);
    printf("%08x\n", R[5]);
    printf("R6=%08x:", R[6]);
    printf("%08x:", R[7]);
    printf("%08x:", R[8]);
    printf("%08x:", R[9]);
    printf("%08x:", R[10]);
    printf("%08x\n", R[11]);
    printf("IP=%08x:", R[12]);
    printf("%08x:", R[13]);
    printf("%08x:", R[14]);
    printf("APSR=%08x:",R[REG_APSR]);
    printf("ITSTATE=%02x\n", ITSTATE);
}
#endif

#define UNPACK_HW(arg) (int16_t)(arg & 0xffff), (int16_t)(arg >> 16)

void pbw_cpu_exec(pbw_cpu cpu, uint32_t ins, uint32_t pc) {
    if (INSTRUCTION_THUMB32(ins)) {
        INS_CALL(thumb2);
    } else {
        INS_CALL(thumb);
    }
    if (cpu->reg[REG_EPSR] & EPSR_MASK_IT && (((ins & 0xff00) != 0xbf00) || INSTRUCTION_THUMB32(ins))) {
        // Advance ITState if in ITBlock
        ITAdvance();
    }
#ifdef PRINT_STATE
    print_regs(cpu);
#endif
}

#pragma mark - ALU Operations

uint32_t pbw_cpu_alu_add(pbw_cpu cpu, uint32_t x, uint32_t y, uint32_t carry_in, uint32_t setflags) {
    uint64_t unsigned_sum = (uint64_t)x + (uint64_t)y + (uint64_t)carry_in;
    int64_t signed_sum = (int64_t)((int32_t)x) + (int64_t)((int32_t)y) + (uint64_t)carry_in;
    uint32_t result = unsigned_sum & 0xFFFFFFFF;
    if (setflags) {
        SetAPSR_NZCV(result, result != unsigned_sum, (int64_t)((int32_t)result) != signed_sum);
    }
    return result;
}

uint32_t pbw_cpu_alu_shift(pbw_cpu cpu, uint32_t value, uint32_t type, uint32_t imm5, uint32_t carry_in, uint32_t setflags) {
    uint32_t result = 0;
    assert(type <= 3);
    switch (type) {
        case 0: result = LSL(value, imm5); break;
        case 1: result = LSR(value, imm5 ?: 32); break;
        case 2: result = ASR(value, imm5 ?: 32); break;
        case 3: result = imm5 ? ROR(value, imm5) : RRX(value, carry_in); break;
    }
    if (setflags) {
        uint32_t carry = carry_in;
        switch (type) {
            case 0: carry = LSL_Carry(value, imm5); break;
            case 1: carry = LSR_Carry(value, imm5 ?: 32); break;
            case 2: carry = ASR_Carry(value, imm5 ?: 32); break;
            case 3: carry = imm5 ? ROR_Carry(value, imm5) : RRX_Carry(value, carry_in); break;
        }
        SetAPSR_NZC(result, carry);
    }
    return result;
}

#pragma mark - Instructions

void pbw_cpu_exec_cbznz(pbw_cpu cpu, uint32_t ins, uint32_t pc) {
    uint32_t n = (ins & 0x7);
    uint32_t imm32 = ((ins & 0x200) >> 3) | ((ins & 0xf8) >> 2);
    uint32_t nonzero = (ins & 0x800) == 0x800;
    if (InITBlock()) {
        CPU_BREAK(UNPREDICTABLE);
    }
    if (nonzero ^ (R[n] == 0)) {
        R[REG_PC] = pc + 4 + imm32;
    }
}

