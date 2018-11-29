//
//  thumb.c
//  Stonework
//
//  Created by Jesús A. Álvarez on 24/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#include "cpu_priv.h"
#include "ops.h"
#include "alu.h"
#include "decode.h"

void pbw_cpu_exec_thumb(pbw_cpu cpu, uint32_t ins, uint32_t pc) {
    int setflags;
    if ((ins & 0xC000) == 0) switch ((ins & 0x3E00) >> 9) {
        case 0x00:
        case 0x01:
        case 0x02:
        case 0x03:
            // MARK: LSL (immediate) T1
        case 0x04:
        case 0x05:
        case 0x06:
        case 0x07:
            // MARK: LSR (immediate) T1
        case 0x08:
        case 0x09:
        case 0x0a:
        case 0x0b:
            // MARK: ASR (immediate) T1
            // MARK: MOV (register) T2
            // MARK: MOV (shifted register)
            if (ConditionPassed()) {
                ENC_2533(type, imm5, m, d);
                setflags = (type == 0 && imm5 == 0) || !LastInITBlock();
                R[d] = pbw_cpu_alu_shift(cpu, R[m], type, imm5, APSR_C, setflags);
            }
            break;
        case 0x0c:
            // MARK: ADD (register) T1
            if (ConditionPassed()) {
                ENC_333(m, n, d);
                setflags = !InITBlock();
                R[d] = pbw_cpu_alu_add(cpu, R[n], R[m], 0, setflags);
            }
            break;
        case 0x0d:
            // MARK: SUB (register) T1
            if (ConditionPassed()) {
                ENC_333(m, n, d);
                setflags = !InITBlock();
                R[d] = pbw_cpu_alu_add(cpu, R[n], ~R[m], 1, setflags);
            }
            break;
        case 0x0e:
            // MARK: ADD (immediate) T1
            if (ConditionPassed()) {
                ENC_333(imm3, n, d);
                setflags = !InITBlock();
                R[d] = pbw_cpu_alu_add(cpu, R[n], imm3, 0, setflags);
            }
            break;
        case 0x0f:
            // MARK: SUB (immediate) T1
            if (ConditionPassed()) {
                ENC_333(imm3, n, d);
                setflags = !InITBlock();
                R[d] = pbw_cpu_alu_add(cpu, R[n], ~(uint32_t)imm3, 1, setflags);
            }
            break;
        case 0x10:
        case 0x11:
        case 0x12:
        case 0x13:
            // MARK: MOV (immediate) T1
            if (ConditionPassed()) {
                ENC_38(d, imm8);
                setflags = !InITBlock();
                uint32_t result = imm8;
                R[d] = result;
                if (setflags) {
                    SetAPSR_NZ(result);
                }
            }
            break;
        case 0x14:
        case 0x15:
        case 0x16:
        case 0x17:
            // MARK: CMP (immediate) T1
            if (ConditionPassed()) {
                ENC_38(n, imm8);
                uint32_t imm32 = imm8;
                pbw_cpu_alu_add(cpu, R[n], ~imm32, 1, 1);
            }
            break;
        case 0x18:
        case 0x19:
        case 0x1a:
        case 0x1b:
            // MARK: ADD (immediate) T2
            if (ConditionPassed()) {
                ENC_38(dn, imm8);
                setflags = !InITBlock();
                uint32_t imm32 = imm8;
                uint32_t result = pbw_cpu_alu_add(cpu, R[dn], imm32, 0, setflags);
                R[dn] = result;
            }
            break;
        case 0x1c:
        case 0x1d:
        case 0x1e:
        case 0x1f:
            // MARK: SUB (immediate) T2
            if (ConditionPassed()) {
                ENC_38(dn, imm8);
                setflags = !InITBlock();
                uint32_t imm32 = imm8;
                uint32_t result = pbw_cpu_alu_add(cpu, R[dn], ~imm32, 1, setflags);
                R[dn] = result;
            }
            break;
        default:
            break;
    } else switch((ins & 0xFC00) >> 10) {
        case 0x10:
            // Data processing
            if (ConditionPassed()) {
                ENC_433(opcode, m, dn);
                setflags = !InITBlock();
                uint32_t result;
                int carry = APSR_C;
                switch (opcode) {
                    case 0: // MARK: AND (register) T1
                        result = R[dn] & R[m];
                        break;
                    case 1: // MARK: EOR (register) T1
                        result = R[dn] ^ R[m];
                        break;
                    case 2: // MARK: LSL (register) T1
                        result = LSL(R[dn], R[m] & 0xff);
                        carry = LSL_Carry(R[dn], R[m] & 0xff);
                        break;
                    case 3: // MARK: LSR (register) T1
                        result = LSR(R[dn], R[m] & 0xff);
                        carry = LSR_Carry(R[dn], R[m] & 0xff);
                        break;
                    case 4: // MARK: ASR (register) T1
                        result = ASR(R[dn], R[m] & 0xff);
                        carry = ASR_Carry(R[dn], R[m] & 0xff);
                        break;
                    case 5: // MARK: ADC (register) T1
                        result = pbw_cpu_alu_add(cpu, R[dn], R[m], carry, setflags);
                        setflags = 0; // already set by pbw_cpu_alu_add
                        break;
                    case 6: // MARK: SBC (register) T1
                        R[dn] = pbw_cpu_alu_add(cpu, R[dn], ~R[m], carry, setflags);
                        return;
                    case 7: // MARK: ROR (register) T1
                        result = ROR(R[dn], R[m] & 0xff);
                        carry = ROR_Carry(R[dn], R[m] & 0xff);
                        break;
                    case 8: // MARK: TST (register) T1
                        result = R[dn] & R[m];
                        SetAPSR_NZ(result);
                        return;
                    case 9: // MARK: RSB (immediate) T1
                        R[dn] = pbw_cpu_alu_add(cpu, ~(R[dn]), 0, 1, setflags);
                        return;
                    case 10: // MARK: CMP (register) T1
                        pbw_cpu_alu_add(cpu, R[dn], ~(R[m]), 1, 1);
                        return;
                    case 11: // MARK: CMN (register) T1
                        pbw_cpu_alu_add(cpu, R[dn], R[m], 0, 1);
                        return;
                    case 12: // MARK: ORR (register) T1
                        result = R[dn] | R[m];
                        break;
                    case 13: // MARK: MUL on page T1 A7-359
                        result = R[dn] * R[m];
                        break;
                    case 14: // MARK: BIC (register) T1
                        result = R[dn] & ~R[m];
                        break;
                    case 15: // MARK: MVN (register) T1
                        result = ~R[m];
                        break;
                    default:
                        result = 0;
                }
                R[dn] = result;
                if (setflags) {
                    SetAPSR_NZC(result, carry);
                }
            }
            break;
        case 0x11: {
            // Special data instructions and branch and exchange
            uint32_t opcode = (ins & 0x03C0) >> 6;
            switch (opcode) {
                case 0:
                case 1:
                case 2:
                case 3:
                    // MARK: ADD (register) T2
                    // MARK: ADD (SP plus register) T1, T2
                    if (ConditionPassed()) {
                        ENC_HsHd(m,dn);
                        if (dn == REG_PC && InITBlock() && !LastInITBlock()) {
                            CPU_BREAK(UNPREDICTABLE);
                        } else if (dn == REG_PC && m == REG_PC) {
                            CPU_BREAK(UNPREDICTABLE);
                        }
                        setflags = 0;
                        uint32_t value = R[m];
                        if (m == REG_PC) value = pc + 4;
                        R[dn] = pbw_cpu_alu_add(cpu, R[dn], value, 0, setflags);
                    }
                    break;
                case 4:
                    CPU_BREAK(UNPREDICTABLE);
                    break;
                case 5:
                case 6:
                case 7:
                    // MARK: CMP (register) T2
                    if (ConditionPassed()) {
                        ENC_HsHd(m, n);
                        if ((n < 8 && m < 8) || n == 15 || m == 15) {
                            CPU_BREAK(UNPREDICTABLE);
                        }
                        uint32_t value = R[m];
                        if (m == REG_PC) value = pc + 4;
                        pbw_cpu_alu_add(cpu, R[n], ~value, 1, 1);
                    }
                    break;
                case 8:
                case 9:
                case 10:
                case 11:
                    // MARK: MOV (register) T1
                    if (ConditionPassed()) {
                        ENC_HsHd(m, d);
                        if (d == 15 && InITBlock() && !LastInITBlock()) {
                            CPU_BREAK(UNPREDICTABLE);
                        }
                        uint32_t value = R[m];
                        if (m == REG_PC) value = pc + 4;
                        R[d] = value;
                    }
                    break;
                case 12:
                case 13:
                case 14:
                case 15:
                    // MARK: BX, BLX
                    if (ConditionPassed()) {
                        uint32_t m = (ins >> 3) & 0xf;
                        if (InITBlock() && !LastInITBlock()) {
                            CPU_BREAK(UNPREDICTABLE);
                        }
                        if (ins & 0x80) {
                            // BLX
                            uint32_t next_instr_addr = pc + 2;
                            cpu->reg[REG_LR] = next_instr_addr;
                        }
                        uint32_t value = R[m];
                        if (m == REG_PC) value = pc + 4;
                        cpu->reg[REG_PC] = value;
                    }
                    break;
                default:
                    break;
            }
            break; }
        case 0x12:
        case 0x13:
            // MARK: LDR (literal) T1
            if (ConditionPassed()) {
                ENC_38(t, imm8);
                uint32_t imm32 = imm8 << 2;
                uint32_t base = Align(pc + 4, 4);
                uint32_t address = base + imm32;
                uint32_t data = pbw_cpu_mem_read(cpu, address, PBW_MEM_READ, PBW_MEM_WORD);
                if (t == REG_PC && (address & 3) != 0) {
                    CPU_BREAK(UNPREDICTABLE);
                }
                R[t] = data;
            }
            break;
        case 0x14:
        case 0x15:
        case 0x16:
        case 0x17:
        case 0x18:
        case 0x19:
        case 0x1a:
        case 0x1b:
        case 0x1c:
        case 0x1d:
        case 0x1e:
        case 0x1f:
        case 0x20:
        case 0x21:
        case 0x22:
        case 0x23:
        case 0x24:
        case 0x25:
        case 0x26:
        case 0x27:
            // MARK: Load/store single data item
            if (ConditionPassed()) {
                INS_CALL(loadstore);
            }
            break;
        case 0x28:
        case 0x29:
            // MARK: ADR (T1)
            if (ConditionPassed()) {
                ENC_38(d, imm8);
                uint32_t imm32 = imm8 << 2;
                uint32_t result = Align(pc + 4, 4) + imm32;
                R[d] = result;
            }
            break;
        case 0x2a:
        case 0x2b:
            // MARK: ADD (SP plus immediate) T1
            if (ConditionPassed()) {
                ENC_38(d, imm8);
                uint32_t imm32 = imm8 << 2;
                R[d] = pbw_cpu_alu_add(cpu, R[REG_SP], imm32, 0, 0);
            }
            break;
        case 0x2c:
        case 0x2d:
        case 0x2e:
        case 0x2f:
            // Miscellaneous 16-bit instructions
            INS_CALL(thumb_misc);
            break;
        case 0x30:
        case 0x31: {
            // MARK: STM, STMIA, STMEA T1
            ENC_38(n, register_list);
            if (register_list == 0) {
                CPU_BREAK(UNPREDICTABLE);
            }
            INS_CALL(stm, n, register_list, 1, 0);
            break; }
        case 0x32:
        case 0x33: {
            // MARK: LDM, LDMIA, LDMFD T1
            ENC_38(n, register_list);
            uint32_t wback = (register_list & (1 << n)) == 0;
            if (register_list == 0) {
                CPU_BREAK(UNPREDICTABLE);
            }
            INS_CALL(ldm, n, register_list, wback, 0);
            break; }
        case 0x34:
        case 0x35:
        case 0x36:
        case 0x37: {
            // Conditional branch, and supervisor call
            ENC_48(cond, imm8);
            if (cond == 0xe) {
                // Permanently UNDEFINED
                CPU_BREAK(UNDEFINED);
            } else if (cond == 0xf) {
                // MARK: SVC
                CPU_BREAK(NOT_IMPLEMENTED);
            }
            // MARK: B T1
            int32_t imm32 = (imm8 & 0x80) ? (0xfffffe00 | (imm8 << 1)) : (imm8 << 1);
            if (InITBlock()) {
                CPU_BREAK(UNPREDICTABLE);
            }
            if (ConditionPassed()) {
                R[REG_PC] = pc + 4 + imm32;
            }
            break; }
        case 0x38:
        case 0x39: {
            // MARK: B T2
            uint32_t imm11 = (ins & 0x7ff);
            int32_t imm32 = (imm11 & 0x400) ? (0xfffff000 | (imm11 << 1)) : (imm11 << 1);
            if (InITBlock() && !LastInITBlock()) {
                CPU_BREAK(UNPREDICTABLE);
            }
            if (ConditionPassed()) {
                R[REG_PC] = pc + 4 + imm32;
            }
            break; }
        default:
            break;
    }
}

void pbw_cpu_exec_thumb_misc(pbw_cpu cpu, uint32_t ins, uint32_t pc) {
    if ((ins & 0xFE0) == 0x660) {
        // MARK: CPS
        CPU_BREAK(NOT_IMPLEMENTED);
        return;
    } else if ((ins & 0xE00) == 0x400) {
        // MARK: PUSH T1
        uint32_t registers = ((ins & 0x100) << 6) | (ins & 0xff);
        if (registers == 0) {
            CPU_BREAK(UNPREDICTABLE);
        }
        INS_CALL(push, registers);
        return;
    } else if ((ins & 0xE00) == 0xC00) {
        // MARK: POP T1
        uint32_t registers = ((ins & 0x100) << 7) | (ins & 0xff);
        if (registers == 0) {
            CPU_BREAK(UNPREDICTABLE);
        }
        INS_CALL(pop, registers);
        return;
    }
    switch ((ins & 0xFC0) >> 6) {
        case 0x00:
        case 0x01:
            // MARK: ADD (SP plus immediate) T2
            if (ConditionPassed()) {
                uint32_t imm32 = (ins & 0x7f) << 2;
                R[REG_SP] = pbw_cpu_alu_add(cpu, R[REG_SP], imm32, 0, 0);
            }
            break;
        case 0x02:
        case 0x03:
            // MARK: SUB (SP minus immediate) T1
            if (ConditionPassed()) {
                uint32_t imm32 = (ins & 0x7f) << 2;
                R[REG_SP] = pbw_cpu_alu_add(cpu, R[REG_SP], ~imm32, 1, 0);
            }
            break;
        case 0x04:
        case 0x05:
        case 0x06:
        case 0x07:
            // MARK: CBNZ, CBZ
            INS_CALL(cbznz);
            break;
        case 0x08: {
            // MARK: SXTH T1
            ENC_33(m, d);
            if (ConditionPassed()) {
                uint16_t value = R[m] & 0xffff;
                R[d] = (value & 0x8000) ? (0xffff0000 | value) : value;
            }
            break; }
        case 0x09: {
            // MARK: SXTB T1
            ENC_33(m, d);
            if (ConditionPassed()) {
                uint8_t value = R[m] & 0xff;
                R[d] = (value & 0x80) ? (0xffffff00 | value) : value;
            }
            break; }
        case 0x0a: {
            // MARK: UXTH T1
            ENC_33(m, d);
            if (ConditionPassed()) {
                R[d] = R[m] & 0xffff;
            }
            break; }
        case 0x0b: {
            // MARK: UXTB T1
            ENC_33(m, d);
            if (ConditionPassed()) {
                R[d] = R[m] & 0xff;
            }
            break; }
        case 0x0c:
        case 0x0d:
        case 0x0e:
        case 0x0f:
        case 0x24:
        case 0x25:
        case 0x26:
        case 0x27:
            // MARK: CBNZ, CBZ
            INS_CALL(cbznz);
            break;
        case 0x28: {
            // MARK: REV T1
            ENC_33(m, d);
            if (ConditionPassed()) {
                R[d] = OSSwapInt32(R[m]);
            }
            break; }
        case 0x29: {
            // MARK: REV16 T1
            ENC_33(m, d);
            if (ConditionPassed()) {
                uint32_t value = R[m];
                uint32_t result = ((value & 0xff) << 8) |
                ((value & 0xff00) >> 8) |
                ((value & 0xff0000) << 8) |
                ((value & 0xff000000) >> 8);
                R[d] = result;
            }
            break; }
        case 0x2b: {
            // MARK: REVSH
            ENC_33(m, d);
            if (ConditionPassed()) {
                uint32_t value = R[m];
                uint32_t result = ((value & 0xff) << 8) |
                ((value & 0xff00) >> 8);
                R[d] = (result & 0x8000) ? (0xffff0000 | result) :  result;
            }
            break; }
        case 0x2c:
        case 0x2d:
        case 0x2e:
        case 0x2f:
            // MARK: CBNZ, CBZ
            INS_CALL(cbznz);
            break;
        case 0x38:
        case 0x39:
        case 0x3a:
        case 0x3b:
            // MARK: BKPT
            CPU_BREAK(BREAKPOINT);
            break;
        case 0x3c:
        case 0x3d:
        case 0x3e:
        case 0x3f: {
            // If-Then, and hints -- If-Then, and hints
            uint32_t mask = (ins & 0x0f);
            if (mask) {
                // MARK: IT
                uint32_t firstcond = (ins & 0xf0) >> 4;
                if (firstcond == 0xf || (firstcond == 0xe && BitCount(mask) != 1)) {
                    CPU_BREAK(UNPREDICTABLE);
                }
                if (InITBlock()) {
                    CPU_BREAK(UNPREDICTABLE);
                }
                SetITSTATE(ins & 0xff);
            } else switch ((ins & 0xf0) >> 4) {
                case 0:
                    // MARK: NOP
                    break;
                case 1:
                    // MARK: YIELD
                    CPU_BREAK(YIELD);
                    break;
                case 2:
                    // MARK: WFE
                    CPU_BREAK(WAIT_FOR_EVENT);
                    break;
                case 3:
                    // MARK: WFI
                    CPU_BREAK(WAIT_FOR_INTERRUPT);
                    break;
                case 4:
                    // MARK: SEV
                    // NOP-compatible;
                    break;
                default:
                    // unallocated, execute as NOP
                    break;
                    
            }
            break; }
    }
}
