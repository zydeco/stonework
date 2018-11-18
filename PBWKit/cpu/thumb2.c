//
//  thumb2.c
//  Stonework
//
//  Created by Jesús A. Álvarez on 24/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#include "cpu_priv.h"
#include "ops.h"
#include "alu.h"
#include "decode.h"

void pbw_cpu_exec_thumb2(pbw_cpu cpu, uint32_t ins, uint32_t pc) {
    if INS_MASK(0xfe400000, 0xe8000000) {
        // Load Multiple and Store Multiple
        uint32_t registers = ins & 0xffff;
        uint32_t n = (ins >> 16) & 0xf;
        uint32_t wback = (ins >> 21) & 1;
        switch ((ins >> 20) & 0xffd) {
        case 0xe88:
            // MARK: STM, STMIA, STMEA T2
            if (n == 15 || BitCount(registers) < 2) {
                CPU_BREAK(UNPREDICTABLE);
            }
            if (wback && ((registers >> n) & 1)) {
                CPU_BREAK(UNPREDICTABLE);
            }
            INS_CALL(stm, n, registers, wback, 0);
            break;
        case 0xe89:
            // MARK: LDM, LDMIA, LDMFD T2
            // MARK: POP T2
            if (n == 15 || BitCount(registers) < 2 || (registers & 0xC000) == 0xC000) {
                CPU_BREAK(UNPREDICTABLE);
            } else if (registers & 0x8000 && InITBlock() && !LastInITBlock()) {
                CPU_BREAK(UNPREDICTABLE);
            } else if (wback && (registers & (1 << n))) {
                CPU_BREAK(UNPREDICTABLE);
            }
            INS_CALL(ldm, n, registers, wback, 0);
            break;
        case 0xe90:
            // MARK: STMDB, STMFD T1
            // MARK: PUSH T2
            INS_CALL(stm, n, registers, wback, 1);
            break;
        case 0xe91:
            // MARK: LDMDB, LDMEA T1
            if (n == 15 || BitCount(registers) < 2 || (registers & 0xC000) == 0xC000) {
                CPU_BREAK(UNPREDICTABLE);
            } else if (registers & 0x8000 && InITBlock() && !LastInITBlock()) {
                CPU_BREAK(UNPREDICTABLE);
            } else if (wback && (registers & (1 << n))) {
                CPU_BREAK(UNPREDICTABLE);
            }
            INS_CALL(ldm, n, registers, wback, 1);
            break;
        default:
            // Other encodings in this space are UNDEFINED
            CPU_BREAK(UNDEFINED);
            break;
        }
    } else if INS_MASK(0xfe400000, 0xe8400000) switch ((ins >> 20) & 0x1b) {
        // Load/store dual or exclusive, table branch
        case 0x08: switch(ins & 0xf0) {
            case 0x40:
                // MARK: STREXB T1
            case 0x50:
                // MARK: STREXH T1
                INS_CALL(loadstore);
                break;
            default:
                CPU_BREAK(UNDEFINED);
                break;
            }
            break;
        case 0x09: switch(ins & 0xf0) {
            case 0x00:
            case 0x10: {
                // MARK: TBB, TBH T1
                uint32_t n = (ins >> 16) & 0xf;
                uint32_t m = ins & 0xf;
                if (n == 13 || m == 13 || m == 15) {
                    CPU_BREAK(UNPREDICTABLE);
                }
                if (InITBlock() && !LastInITBlock()) {
                    CPU_BREAK(UNPREDICTABLE);
                }
                if (ConditionPassed()) {
                    int is_tbh = (ins & 0x10);
                    uint32_t base = (n == REG_PC) ? pc + 4 : R[n];
                    uint32_t offset;
                    if (is_tbh) {
                        uint32_t addr = base + (R[m] << 1);
                        offset = pbw_cpu_mem_read(cpu, addr, PBW_MEM_READ, PBW_MEM_HALFWORD);
                    } else {
                        uint32_t addr = base + R[m];
                        offset = pbw_cpu_mem_read(cpu, addr, PBW_MEM_READ, PBW_MEM_BYTE);
                    }
                    R[REG_PC] = pc + 4 + (2 * offset);
                }
                break; }
            case 0x40:
                // MARK: LDREXB T1
            case 0x50:
                // MARK: LDREXH T1
                INS_CALL(loadstore);
                break;
            default:
                CPU_BREAK(UNDEFINED);
                break;
            }
            break;
        default:
            // MARK: STREX T1
            // MARK: LDREX T1
            // MARK: STRD T1
            // MARK: LDRD (immediate) T1
            // MARK: LDRD (literal) T1
            INS_CALL(loadstore);
            break;
    } else if INS_MASK(0xfe000000, 0xea000000) {
        // Data processing (shifted register)
        uint32_t op = (ins >> 21) & 0xf;
        uint32_t n = (ins >> 16) & 0xf;
        uint32_t d = (ins >> 8) & 0xf;
        uint32_t m = ins & 0xf;
        uint32_t imm5 = ((ins >> 10) & 0x1c) | ((ins >> 6) & 0x3);
        uint32_t shift_type = (ins >> 4) & 3;
        uint32_t setflags = (ins >> 20) & 1;
        uint32_t value = (m == REG_PC) ? pc + 4 : R[m];
        switch (op) {
            case 0x0:
                if (d != 0xf) {
                    // MARK: AND (register) T2
                    if (d == 13 || n == 13 || n == 15 || m == 13 || m == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        uint32_t shifted = pbw_cpu_alu_shift(cpu, value, shift_type, imm5, APSR_C, setflags);
                        R[d] = R[n] & shifted;
                        if (setflags) {
                            SetAPSR_NZ(shifted);
                        }
                    }
                } else if (setflags) {
                    // MARK: TST (register) T2
                    if (n == 13 || n == 15 || m == 13 || m == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        uint32_t shifted = pbw_cpu_alu_shift(cpu, value, shift_type, imm5, APSR_C, setflags);
                        uint32_t result = R[n] & shifted;
                        SetAPSR_NZ(result);
                    }
                } else {
                    CPU_BREAK(UNPREDICTABLE);
                }
                break;
            case 0x1:
                // MARK: BIC (register) T2
                if (d == 13 || d == 15 || n == 13 || n == 15 || m == 13 || m == 15) {
                    CPU_BREAK(UNPREDICTABLE);
                }
                if (ConditionPassed()) {
                    uint32_t shifted = pbw_cpu_alu_shift(cpu, value, shift_type, imm5, APSR_C, setflags);
                    uint32_t result = R[n] & ~shifted;
                    R[d] = result;
                    if (setflags) {
                        SetAPSR_NZ(result);
                    }
                }
                break;
            case 0x2:
                if (n != 0xf) {
                    // MARK: ORR (register) T2
                    if (d == 13 || d == 15 || n == 13 || m == 13 || m == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        uint32_t shifted = pbw_cpu_alu_shift(cpu, value, shift_type, imm5, APSR_C, setflags);
                        uint32_t result = R[n] | shifted;
                        R[d] = result;
                        if (setflags) {
                            SetAPSR_NZ(result);
                        }
                    }
                } else {
                    // Move register and immediate shifts
                    // MARK: MOV (register) T3
                    // MARK: LSL (immediate) T2
                    // MARK: LSR (immediate) T2
                    // MARK: ASR (immediate) T2
                    // MARK: RRX (immediate) T1
                    // MARK: ROR (immediate) T1
                    if (ConditionPassed()) {
                        uint32_t shifted = pbw_cpu_alu_shift(cpu, value, shift_type, imm5, APSR_C, setflags);
                        R[d] = shifted;
                    }
                }
                break;
            case 0x3:
                if (n != 0xf) {
                    // MARK: ORN (register) T1
                    if (d == 13 || d == 15 || n == 13 || m == 13 || m == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        uint32_t shifted = pbw_cpu_alu_shift(cpu, value, shift_type, imm5, APSR_C, setflags);
                        uint32_t result = R[n] | ~shifted;
                        R[d] = result;
                        if (setflags) {
                            SetAPSR_NZ(result);
                        }
                    }
                } else {
                    // MARK: MVN (register) T2
                    if (d == 13 || d == 15 || m == 13 || m == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        uint32_t shifted = pbw_cpu_alu_shift(cpu, value, shift_type, imm5, APSR_C, setflags);
                        uint32_t result = ~shifted;
                        R[d] = result;
                        if (setflags) {
                            SetAPSR_NZ(result);
                        }
                    }
                }
                break;
            case 0x4:
                if (d != 0xf) {
                    // MARK: EOR (register) T2
                    if (d == 13 || n == 13 || n == 15 || m == 13 || m == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        uint32_t shifted = pbw_cpu_alu_shift(cpu, value, shift_type, imm5, APSR_C, setflags);
                        uint32_t result = R[n] ^ shifted;
                        R[d] = result;
                        if (setflags) {
                            SetAPSR_NZ(result);
                        }
                    }
                } else if (setflags) {
                    // MARK: TEQ (register) T1
                    if (n == 13 || n == 15 || m == 13 || m == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        uint32_t shifted = pbw_cpu_alu_shift(cpu, value, shift_type, imm5, APSR_C, setflags);
                        uint32_t result = R[n] ^ shifted;
                        SetAPSR_NZ(result);
                    }
                } else {
                    CPU_BREAK(UNPREDICTABLE);
                }
                break;
            case 0x6:
                // MARK: PKHBT, PKHTB T1 (v7E-M)
                if (d == 13 || d == 15 || n == 13 || n == 15 || m == 13 || m == 15) {
                    CPU_BREAK(UNPREDICTABLE);
                }
                if (ConditionPassed()) {
                    // undefined with T = 0, so shift_type should still be 0bx0
                    uint32_t operand2 = pbw_cpu_alu_shift(cpu, value, shift_type, imm5, 0, 0);
                    uint32_t tbform = shift_type; // 0b10 or 0b00
                    if (tbform) {
                        R[d] = (R[n] & 0xffff0000) | (operand2 & 0xffff);
                    } else {
                        R[d] = (operand2 & 0xffff0000) | (R[n] & 0xffff);
                    }
                }
                break;
            case 0x8:
                if (d != 0xf) {
                    // MARK: ADD (register) T3
                    if (d == 13 || n == 15 || m == 13 || m == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        if (d == 15) {
                            setflags = 0;
                        }
                        uint32_t shifted = pbw_cpu_alu_shift(cpu, value, shift_type, imm5, APSR_C, setflags);
                        R[d] = pbw_cpu_alu_add(cpu, R[n], shifted, 0, setflags);
                    }
                } else if (setflags) {
                    // MARK: CMN (register) T2
                    if (n == 15 || m == 13 || m == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        uint32_t shifted = pbw_cpu_alu_shift(cpu, value, shift_type, imm5, APSR_C, setflags);
                        pbw_cpu_alu_add(cpu, R[n], shifted, 0, 1);
                    }
                } else {
                    CPU_BREAK(UNPREDICTABLE);
                }
                break;
            case 0xa:
                // MARK: ADC (register) T2
            case 0xb:
                // MARK: SBC (register) T2
                if (d == 13 || d == 15 || n == 13 || n == 15 || m == 13 || m == 15) {
                    CPU_BREAK(UNPREDICTABLE);
                }
                if (ConditionPassed()) {
                    uint32_t shifted = pbw_cpu_alu_shift(cpu, value, shift_type, imm5, APSR_C, 0);
                    if (op == 0xb) shifted = ~shifted;
                    R[d] = pbw_cpu_alu_add(cpu, R[n], shifted, APSR_C, setflags);
                }
                break;
            case 0xd:
                if (d != 0xf) {
                    // MARK: SUB (register) T2
                    if (n == 15 || m == 13 || m == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        uint32_t shifted = pbw_cpu_alu_shift(cpu, value, shift_type, imm5, APSR_C, setflags);
                        R[d] = pbw_cpu_alu_add(cpu, R[n], ~shifted, 1, setflags);
                    }
                } else if (setflags) {
                    // MARK: CMP (register) T3
                    if (n == 15 || m == 13 || m == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        uint32_t shifted = pbw_cpu_alu_shift(cpu, value, shift_type, imm5, APSR_C, 0);
                        pbw_cpu_alu_add(cpu, R[n], ~shifted, 1, 1);
                    }
                } else {
                    CPU_BREAK(UNPREDICTABLE);
                }
                break;
            case 0xe:
                // MARK: RSB (register) T1
                if (d == 13 || d == 15 || n == 13 || n == 15 || m == 13 || m == 15) {
                    CPU_BREAK(UNPREDICTABLE);
                }
                if (ConditionPassed()) {
                    uint32_t shifted = pbw_cpu_alu_shift(cpu, value, shift_type, imm5, APSR_C, 0);
                    R[d] = pbw_cpu_alu_add(cpu, ~R[n], shifted, 1, setflags);
                }
                break;
            default:
                // Other encodings in this space are UNDEFINED
                CPU_BREAK(UNPREDICTABLE);
                break;
        }
    } else if INS_MASK(0xec000000, 0xec000000) {
        // Coprocessor instructions
        // Should cause UsageFault with UFSR.NOCP
        CPU_BREAK(NOT_IMPLEMENTED);
    } else if INS_MASK(0xfa008000, 0xf0000000) {
        // Data processing (modified immediate)
        uint32_t n = (ins >> 16) & 0xf;
        uint32_t d = (ins >> 8) & 0xf;
        uint32_t setflags = (ins >> 20) & 1; // bit 4+16
        switch ((ins >> 21) & 0xf) {
            case 0:
                if (d == 0xf) {
                    // MARK: TST (immediate) T1
                    if (n == 13 || n == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        ENC_ThumbExpandImm_C(result, carry);
                        result &= R[n];
                        SetAPSR_NZC(result, carry);
                    }
                } else {
                    // MARK: AND (immediate) T1
                    if (d == 13 || n == 13 || n == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        ENC_ThumbExpandImm_C(imm32, carry);
                        uint32_t result = R[n] & imm32;
                        R[d] = result;
                        SetAPSR_NZC(result, carry);
                    }
                }
                break;
            case 1:
                // MARK: BIC (immediate) T1
                if (d == 13 || d == 15 || n == 13 || n == 15) {
                    CPU_BREAK(UNPREDICTABLE);
                }
                if (ConditionPassed()) {
                    ENC_ThumbExpandImm_C(imm32, carry);
                    uint32_t result = R[n] & ~imm32;
                    R[d] = result;
                    if (setflags) {
                        SetAPSR_NZC(result, carry);
                    }
                }
                break;
            case 2:
                if (n == 0xf) {
                    // MARK: MOV (immediate) T2
                    if (d == 13 || d == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        ENC_ThumbExpandImm_C(result, carry);
                        R[d] = result;
                        if (setflags) {
                            SetAPSR_NZC(result, carry);
                        }
                    }
                } else {
                    // MARK: ORR (immediate) T1
                    if (d == 13 || d == 15 || n == 13) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        ENC_ThumbExpandImm_C(imm32, carry);
                        uint32_t result = R[n] | imm32;
                        R[d] = result;
                        if (setflags) {
                            SetAPSR_NZC(result, carry);
                        }
                    }
                }
                break;
            case 3:
                if (n == 0xf) {
                    // MARK: MVN (immediate) T1
                    if (d == 13 || d == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        ENC_ThumbExpandImm_C(result, carry);
                        result = ~result;
                        R[d] = result;
                        if (setflags) {
                            SetAPSR_NZC(result, carry);
                        }
                    }
                } else {
                    // MARK: ORN (immediate) T1
                    if (d == 13 || d == 15 || n == 13) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        ENC_ThumbExpandImm_C(imm32, carry);
                        uint32_t result = R[n] | ~imm32;
                        R[d] = result;
                        if (setflags) {
                            SetAPSR_NZC(result, carry);
                        }
                    }
                }
                break;
            case 4:
                if (d == 0xf) {
                    // MARK: TEQ (immediate) T1
                    if (n == 13 || n == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        ENC_ThumbExpandImm_C(imm32, carry);
                        uint32_t result = R[n] ^ imm32;
                        SetAPSR_NZC(result, carry);
                    }
                } else {
                    // MARK: EOR (immediate) T1
                    if (d == 13 || n == 13 || n == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        ENC_ThumbExpandImm_C(imm32, carry);
                        uint32_t result = R[n] ^ imm32;
                        R[d] = result;
                        if (setflags) {
                            SetAPSR_NZC(result, carry);
                        }
                    }
                }
                break;
            case 8:
                if (d == 0xf) {
                    // MARK: CMN (immediate) T1
                    if (n == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        ENC_ThumbExpandImm(imm32);
                        pbw_cpu_alu_add(cpu, R[n], imm32, 0, 1);
                    }
                } else {
                    // MARK: ADD (immediate) T3
                    if (d == 13 || n == 15) {
                        CPU_BREAK(UNPREDICTABLE)
                    }
                    if (ConditionPassed()) {
                        ENC_ThumbExpandImm(imm32);
                        R[d] = pbw_cpu_alu_add(cpu, R[n], imm32, 0, setflags);
                    }
                }
                break;
            case 10:
                // MARK: ADC (immediate) T1
                if (d == 13 || d == 15 || n == 13 || n == 15) {
                    CPU_BREAK(UNPREDICTABLE);
                }
                if (ConditionPassed()) {
                    ENC_ThumbExpandImm(imm32);
                    R[d] = pbw_cpu_alu_add(cpu, R[n], imm32, APSR_C, setflags);
                }
                break;
            case 11:
                // MARK: SBC (immediate) T1
                if (d == 13 || d == 15 || n == 13 || n == 15) {
                    CPU_BREAK(UNPREDICTABLE);
                }
                if (ConditionPassed()) {
                    ENC_ThumbExpandImm(imm32);
                    R[d] = pbw_cpu_alu_add(cpu, R[n], ~imm32, APSR_C, setflags);
                }
                break;
            case 13:
                if (d == 0xf) {
                    // MARK: CMP (immediate) T2
                    if (n == 15) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        ENC_ThumbExpandImm(imm32);
                        pbw_cpu_alu_add(cpu, R[n], ~imm32, 1, 1);
                    }
                } else {
                    // MARK: SUB (immediate) T3
                    ENC_ThumbExpandImm(imm32);
                    if (d == 13 || (d == 15 && !setflags) || n == 15) {
                        CPU_BREAK(UNPREDICTABLE)
                    }
                    if (ConditionPassed()) {
                        R[d] = pbw_cpu_alu_add(cpu, R[n], ~imm32, 1, setflags);
                    }
                }
                break;
            case 14:
                // MARK: RSB (immediate) T2
                if (d == 13 || d == 15 || n == 13 || n == 15) {
                    CPU_BREAK(UNPREDICTABLE);
                }
                if (ConditionPassed()) {
                    ENC_ThumbExpandImm(imm32);
                    R[d] = pbw_cpu_alu_add(cpu, ~R[n], imm32, 1, setflags);
                }
                break;
            default:
                CPU_BREAK(UNDEFINED);
                break;
        }
    } else if INS_MASK(0xfa008000, 0xf2000000) {
        // Data processing (plain binary immediate)
        uint32_t n = (ins >> 16) & 0xf;
        uint32_t d = (ins >> 8) & 0xf;
        ENC_ThumbImm16(imm32);
        switch ((ins >> 20) & 0x1f) {
            case 0x00:
                if (n == 0xf) {
                    // MARK: ADR T3
                    CPU_BREAK(NOT_IMPLEMENTED);
                } else {
                    // MARK: ADD (immediate) T4
                    CPU_BREAK(NOT_IMPLEMENTED);
                }
                break;
            case 0x04: {
                // MARK: MOV (immediate) T3
                if (d == 13 || d == 15) {
                    CPU_BREAK(UNPREDICTABLE);
                }
                if (ConditionPassed()) {
                    R[d] = imm32;
                }
                break; }
            case 0x0a:
                if (n == 0xf) {
                    // MARK: ADR T2
                    CPU_BREAK(NOT_IMPLEMENTED);
                } else {
                    // MARK: SUB (immediate) T4
                    CPU_BREAK(NOT_IMPLEMENTED);
                }
                break;
            case 0x0c:
                // MARK: MOVT T1
                CPU_BREAK(NOT_IMPLEMENTED);
                break;
            case 0x10:
            case 0x12:
                // MARK: SSAT T1, SSAT16 T1
                CPU_BREAK(NOT_IMPLEMENTED);
                break;
            case 0x14:
                // MARK: SBFX T1
                CPU_BREAK(NOT_IMPLEMENTED);
                break;
            case 0x16:
                if (n == 0xf) {
                    // MARK: BFC T1
                    CPU_BREAK(NOT_IMPLEMENTED);
                } else {
                    // MARK: BFI T1
                    CPU_BREAK(NOT_IMPLEMENTED);
                }
                break;
            case 0x18:
            case 0x1a:
                // MARK: USAT T1, USAT16 T1
                CPU_BREAK(NOT_IMPLEMENTED);
                break;
            case 0x1c:
                // MARK: UBFX T1
                if (d == 13 || d == 15 || n == 13 || n == 15) {
                    CPU_BREAK(UNPREDICTABLE);
                }
                if (ConditionPassed()) {
                    uint32_t lsbit = ((ins >> 10) & 0x1c) | ((ins >> 6) & 0x3);
                    uint32_t widthminus1 = ins & 0x1f;
                    uint32_t msbit = lsbit + widthminus1;
                    if (msbit <= 31) {
                        uint32_t value = R[n];
                        uint32_t result = (value >> lsbit) & ~(0xffffffff << (widthminus1 + 1));
                        R[d] = result;
                    } else {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                }
                break;
            default:
                CPU_BREAK(UNDEFINED);
                break;
        }
    } else if INS_MASK(0xf8008000, 0xf0008000) {
        // Branches and miscellaneous control
        uint32_t op1 = (ins >> 12) & 0x7;
        uint32_t op = (ins >> 20) & 0x7f;
        if ((op1 & 0x5) == 0) switch (op) {
            case 0x38:
            case 0x39:
                // MARK: MSR T1
                CPU_BREAK(NOT_IMPLEMENTED);
                break;
            case 0x3a:
                // TODO: Hints
                CPU_BREAK(NOT_IMPLEMENTED);
                break;
            case 0x3b:
                // TODO: Miscellaneous control instructions
                break;
            case 0x3e:
            case 0x3f:
                // MARK: MRS: T1
                CPU_BREAK(NOT_IMPLEMENTED);
                break;
            default:
                if ((op & 0x38) != 0x38) {
                    // MARK: B T3
                    int32_t imm32 = ((ins & 0x7ff) << 1) | // imm11
                    ((ins & 0x3F0000) >> 4) | // imm6
                    ((ins & 0x2000) << 5) | // J1
                    ((ins & 0x800) << 8) | // J2
                    ((ins & 0x4000000) ? 0xfff00000 : 0 ); // sign-extend
                    if (InITBlock()) {
                        CPU_BREAK(UNPREDICTABLE);
                    }
                    if (ConditionPassed()) {
                        R[REG_PC] = pc + 4 + imm32;
                    }
                } else {
                    CPU_BREAK(UNDEFINED);
                }
        } else if ((op1 & 0x1) == 1) {
            // MARK: B T4
            // MARK: BL T1
            uint32_t j1 = (ins >> 13) & 1;
            uint32_t j2 = (ins >> 11) & 1;
            uint32_t s = (ins >> 26) & 1;
            uint32_t i1 = !(j1 ^ s);
            uint32_t i2 = !(j2 ^ s);
            int32_t imm32 = ((ins & 0x7ff) << 1) | // imm11
            ((ins & 0x3ff0000) >> 4) | // imm10
            (i2 << 22) | (i1 << 23) | (s ? 0xff000000: 0);
            if (InITBlock() && !LastInITBlock()) {
                CPU_BREAK(UNPREDICTABLE);
            }
            if (ConditionPassed()) {
                if (ins & 0x4000) { // BL
                    uint32_t next_instr_addr = pc + 4;
                    R[REG_LR] = next_instr_addr;
                }
                R[REG_PC] = pc + 4 + imm32;
            }
        } else {
            CPU_BREAK(UNDEFINED);
        }
    } else if INS_MASK(0xfe000000, 0xf8000000) {
        // Store single data item
        // Load byte, memory hints and
        // Load halfword, memory hints
        // Load word
        INS_CALL(loadstore);
    } else if INS_MASK(0xff000000, 0xfa000000) {
        // Data processing (register)
        uint32_t op1 = (ins >> 20) & 0xf;
        uint32_t n = (ins >> 16) & 0xf;
        uint32_t op2 = (ins >> 4) & 0xf;
        if ((op2 == 0) && ((op1 & 0x8) == 0)) {
            uint32_t d = (ins >> 8) & 0xf;
            uint32_t m = ins & 0xf;
            if (d == 13 || d == 15 || n == 13 || n == 15 || m == 13 || m == 15) {
                CPU_BREAK(UNPREDICTABLE);
            }
            if (ConditionPassed()) {
                uint32_t value = R[n];
                uint32_t shift_n = R[m] & 0xff;
                uint32_t result = 0;
                uint32_t carry = 0;
                int setflags = ins & 0x100000;
                switch (op1) {
                    case 0x0:
                    case 0x1:
                        // MARK: LSL (register) T2
                        result = LSL(value, shift_n);
                        carry = LSL_Carry(value, shift_n);
                        break;
                    case 0x2:
                    case 0x3:
                        // MARK: LSR (register) T2
                        result = LSR(value, shift_n);
                        carry = LSR_Carry(value, shift_n);
                        break;
                    case 0x4:
                    case 0x5:
                        // MARK: ASR (register) T2
                        result = ASR(value, shift_n);
                        carry = ASR_Carry(value, shift_n);
                        break;
                    case 0x6:
                    case 0x7:
                        // MARK: ROR (register) T2
                        result = ROR(value, shift_n);
                        carry = ROR_Carry(value, shift_n);
                        break;
                }
                R[d] = result;
                if (setflags) {
                    SetAPSR_NZC(result, carry);
                }
            }
        } else if (op1 <= 5 && (op2 & 0x8)) {
            // (S,U)XT[A](H,B,B16)
            uint32_t d = (ins >> 8) & 0xf;
            uint32_t m = ins & 0xf;
            if (d == 13 || d== 15 || n == 13 || m == 13 || m == 15) {
                CPU_BREAK(UNPREDICTABLE);
            }
            if (ConditionPassed()) {
                uint32_t rotation = (ins & 0x30) >> 1;
                uint32_t rotated = ROR(R[m], rotation);
                uint32_t addend = n == 15 ? 0 : R[n];
                switch (op1) {
                    case 0:
                        // MARK: SXTAH T1
                        // MARK: SXTH T2
                        R[d] = addend + SignExtend16to32(rotated & 0xffff);
                        break;
                    case 1:
                        // MARK: UXTAH T1
                        // MARK UXTH T2
                        R[d] = addend + (rotated & 0xffff);
                        break;
                    case 2:
                        // MARK: SXTAB T1
                        // MARK: SXTB T1
                        R[d] = (addend & 0xffff) + SignExtend8to16(rotated & 0xff) | (((addend >> 16) + SignExtend8to16((rotated >> 16) & 0xff)) << 16);
                        break;
                    case 3:
                        // MARK: UXTAB T1
                        // MARK: UXTB T1
                        R[d] = (addend & 0xffff) + (rotated & 0xff) | (((addend >> 16) + ((rotated >> 16) & 0xff)) << 16);
                        break;
                    case 4:
                        // MARK: SXTAB T1
                        // MARK: SXTB T2
                        R[d] = addend + SignExtend8to32(rotated & 0xff);
                        break;
                    case 5:
                        // MARK: UXTAB T1
                        // MARK: UXTB T2
                        R[d] = addend + (rotated & 0xff);
                        break;
                }
            }
        } else if (op1 & 0x8 && ((op2 & 0xc) == 0)) {
            // Parallel addition and substraction, signed
            CPU_BREAK(NOT_IMPLEMENTED);
        } else if (op1 & 0x8 && ((op2 & 0xc) == 0x4)) {
            // Parallel addition and substraction, unsigned
            CPU_BREAK(NOT_IMPLEMENTED);
        } else if (((op1 & 0xc) == 0x8) && ((op2 & 0xc) == 0x8)) {
            // Miscellaneous operations
            INS_CALL(thumb2_misc);
        } else {
            CPU_BREAK(UNDEFINED);
        }
    } else if INS_MASK(0xff800000, 0xfb000000) {
        // Multiply, multiply accumulate, and absolute difference
        uint32_t op1 = (ins >> 20) & 0x7;
        uint32_t op2 = (ins >> 4) & 0x3;
        uint32_t n = (ins >> 16) & 0xf;
        uint32_t a = (ins >> 12) & 0xf;
        uint32_t d = (ins >> 8) & 0xf;
        uint32_t m = ins & 0xf;
        if (op1 == 0 && op2 == 0) {
            if (a == 0xf) {
                // MARK: MUL T2
                if (d == 13 || d == 15 || n == 13 || n == 15 || m == 13 || m == 15) {
                    CPU_BREAK(UNPREDICTABLE);
                }
                if (ConditionPassed()) {
                    uint64_t operand1 = R[n];
                    uint64_t operand2 = R[m];
                    uint64_t result = operand1 * operand2;
                    R[d] = result & 0xffffffff;
                }
            } else {
                // MARK: MLA T1
                if (d == 13 || d == 15 || n == 13 || n == 15 || m == 13 || m == 15 || a == 13) {
                    CPU_BREAK(UNPREDICTABLE);
                }
                if (ConditionPassed()) {
                    uint64_t operand1 = R[n];
                    uint64_t operand2 = R[m];
                    uint64_t addend = R[a];
                    uint64_t result = operand1 * operand2 + addend;
                    R[d] = result & 0xffffffff;
                }
            }
        } else if (op1 == 0 && op2 == 1) {
            // MARK: MLS T1
            if (n == 13 || n == 15 || a == 13 || a == 15 || d == 13 || d == 15 || m == 13 || m == 15) {
                CPU_BREAK(UNPREDICTABLE);
            }
            if (ConditionPassed()) {
                int32_t operand1 = R[n];
                int32_t operand2 = R[m];
                int32_t addend = R[a];
                int32_t result = addend - (operand1 * operand2);
                R[d] = result;
            }
        } else {
            CPU_BREAK(NOT_IMPLEMENTED);
        }
    } else if INS_MASK(0xff800000, 0xfb800000) {
        // TODO: Long multiply, long multiply accumulate, and divide
        uint32_t op1 = (ins >> 20) & 0x7;
        uint32_t op2 = (ins >> 4) & 0xf;
        uint32_t n = (ins >> 16) & 0xf;
        uint32_t dLo = (ins >> 12) & 0xf;
        uint32_t dHi = (ins >> 8) & 0xf;
        uint32_t m = ins & 0xf;
        if (op1 == 0b001 && op2 == 0b1111) {
            // MARK: SDIV T1
            // dHi is d, dLo is 0b1111
            if (dHi == 13 || dHi == 15 || n == 13 || n == 15 || m == 13 || m == 15) {
                CPU_BREAK(UNPREDICTABLE);
            }
            if (ConditionPassed()) {
                int32_t nValue = R[n];
                int32_t mValue = R[m];
                int32_t result = mValue ? (nValue / mValue) : 0;
                R[dHi] = result;
            }
        } else if (op1 == 0b010 && op2 == 0b0000) {
            // MARK: UMULL T1
            if (ConditionPassed()) {
                uint64_t result = (uint64_t)R[n] * (uint64_t)R[m];
                R[dHi] = result >> 32;
                R[dLo] = (result & 0xffffffff);
            }
        } else if (op1 == 0b011 && op2 == 0b1111) {
            // MARK: UDIV T1
            // dHi is d, dLo is 0b1111
            if (dHi == 13 || dHi == 15 || n == 13 || n == 15 || m == 13 || m == 15) {
                CPU_BREAK(UNPREDICTABLE);
            }
            if (ConditionPassed()) {
                int32_t nValue = R[n];
                int32_t mValue = R[m];
                int32_t result = mValue ? (nValue / mValue) : 0;
                R[dHi] = result;
            }
        } else {
            CPU_BREAK(NOT_IMPLEMENTED);
        }
    } else {
        // What is this?
        CPU_BREAK(UNDEFINED);
    }
}

void pbw_cpu_exec_thumb2_misc(pbw_cpu cpu, uint32_t ins, uint32_t pc) {
    uint32_t n = (ins >> 16) & 0xf;
    uint32_t d = (ins >> 8) & 0xf;
    uint32_t m = ins & 0xf;
    if (n == 13 || n == 15 || d == 13 || d == 15 || m == 13 || m == 15) {
        CPU_BREAK(UNPREDICTABLE);
    }
    switch (((ins >> 18) & 0xc) | ((ins >> 4) & 0x3)) {
        case 0b0000:
            // MARK: QADD
            CPU_BREAK(NOT_IMPLEMENTED);
            break;
        case 0b0001:
            // MARK: QDADD
            CPU_BREAK(NOT_IMPLEMENTED);
            break;
        case 0b0010:
            // MARK: QSUB
            CPU_BREAK(NOT_IMPLEMENTED);
            break;
        case 0b0011:
            // MARK: QDSUB
            CPU_BREAK(NOT_IMPLEMENTED);
            break;
        case 0b0100:
            // MARK: REV T2
            if (ConditionPassed()) {
                R[d] = OSSwapInt32(R[m]);
            }
            break;
        case 0b0101:
            // MARK: REV16 T2
            if (ConditionPassed()) {
                uint32_t value = R[m];
                uint32_t result = ((value & 0xff) << 8) |
                ((value & 0xff00) >> 8) |
                ((value & 0xff0000) << 8) |
                ((value & 0xff000000) >> 8);
                R[d] = result;
            }
            break;
        case 0b0110:
            // MARK: RBIT
            if (ConditionPassed()) {
                uint32_t value = R[m];
                uint32_t result = 0;
                for (int b = 0; b < 32; b++) {
                    result |= ((value >> b) & 1) << (31 - b);
                }
                R[d] = result;
            }
            break;
        case 0b0111:
            // MARK: REVSH T2
            if (ConditionPassed()) {
                uint32_t value = R[m];
                uint32_t result = ((value & 0xff) << 8) |
                ((value & 0xff00) >> 8);
                R[d] = (result & 0x8000) ? (0xffff0000 | result) :  result;
            }
            break;
        case 0b1000:
            // MARK: SEL T1
            if (ConditionPassed()) {
                uint32_t nmask = 0;
                if (APSR_GE & 0b0001) nmask |= 0xff;
                if (APSR_GE & 0b0010) nmask |= 0xff00;
                if (APSR_GE & 0b0100) nmask |= 0xff0000;
                if (APSR_GE & 0b1000) nmask |= 0xff000000;
                R[d] = (R[n] & nmask) | (R[m] & ~nmask);
            }
            break;
        case 0b1100:
            // MARK: CLZ T1
            if (ConditionPassed()) {
#if defined(__SIZEOF_INT__) && __SIZEOF_INT__ == 4 && __has_builtin(__builtin_clz)
                R[d] = R[m] ? __builtin_clz(R[m]) : 32;
#else
#error builtin_clz not available
#endif
            }
            break;
        default:
            CPU_BREAK(NOT_IMPLEMENTED);
            break;
    }
}
