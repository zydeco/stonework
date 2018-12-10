//
//  memory.c
//  Stonework
//
//  Created by Jesús A. Álvarez on 15/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#include "cpu_priv.h"
#include "ops.h"
#include "alu.h"
#include "decode.h"
#include <string.h>

struct pbw_mem_region *pbw_cpu_mem_region(pbw_cpu cpu, uint32_t addr, pbw_mem_op op) {
    for (int i=0; i < MAX_MEM_REGIONS; i++) {
        struct pbw_mem_region *rgn = &cpu->mem_regions[i];
        if (rgn->access == NULL) break;
        if ((addr >= rgn->begin) && (addr < rgn->end)) {
            return (rgn->perms & op) ? rgn : NULL;
        }
    }
    return NULL;
}

// default memory access hook: read/write to pointer-backed memory
uint32_t pbw_cpu_mem_access(pbw_cpu cpu, void *ptr, uint32_t offset, pbw_mem_op op, pbw_mem_size size, uint32_t value) {
    uint8_t *base = (uint8_t*)ptr;
    if (op == PBW_MEM_WRITE) {
        switch (size) {
            case PBW_MEM_BYTE:
                base[offset] = value;
                break;
            case PBW_MEM_HALFWORD:
                OSWriteLittleInt16(base, offset, value);
                break;
            case PBW_MEM_WORD:
                OSWriteLittleInt32(base, offset, value);
                break;
            default:
                abort();
        }
        return value;
    } else if (op == PBW_MEM_READ || op == PBW_MEM_EXEC) {
        switch (size) {
            case PBW_MEM_BYTE: return base[offset];
            case PBW_MEM_HALFWORD: return OSReadLittleInt16(base, offset);
            case PBW_MEM_WORD: return OSReadLittleInt32(base, offset);
            default:
                abort();
        }
    } else {
        abort();
    }
}

uint32_t pbw_cpu_mem_read(pbw_cpu cpu, uint32_t addr, pbw_mem_op op, pbw_mem_size size) {
    struct pbw_mem_region *rgn = pbw_cpu_mem_region(cpu, addr, op);
    if (rgn) {
        return rgn->access(cpu, rgn->ptr, addr-rgn->begin, op, size, 0);
    } else {
        return cpu->invalid_access(cpu, cpu->userData, addr, PBW_MEM_READ, size, 1);
    }
}

uint32_t pbw_cpu_mem_write(pbw_cpu cpu, uint32_t addr, pbw_mem_size size, uint32_t value) {
    struct pbw_mem_region *rgn = pbw_cpu_mem_region(cpu, addr, PBW_MEM_WRITE);
    if (rgn) {
        return rgn->access(cpu, rgn->ptr, addr-rgn->begin, PBW_MEM_WRITE, size, value);
    } else {
        return cpu->invalid_access(cpu, cpu->userData, addr, PBW_MEM_WRITE, size, value);
    }
}

int pbw_cpu_mem_map_ptr(pbw_cpu cpu, uint32_t address, uint32_t size, int perms, void *ptr) {
    return pbw_cpu_mem_map_func(cpu, address, size, perms, pbw_cpu_mem_access, ptr);
}

int pbw_cpu_mem_map_func(pbw_cpu cpu, uint32_t address, uint32_t size, int perms, pbw_cpu_hook hook, void *userData) {
    for (int i=0; i < MAX_MEM_REGIONS; i++) {
        struct pbw_mem_region *rgn = &cpu->mem_regions[i];
        if (rgn->access == NULL) {
            rgn->begin = address;
            rgn->end = address + size;
            rgn->perms = perms;
            rgn->access = hook;
            rgn->ptr = userData;
            return i;
        }
    }
    return -PBW_ERR_MEM_LIMIT;
}

int pbw_cpu_hook_exec(pbw_cpu cpu, uint32_t address, uint32_t size, pbw_cpu_hook hook, void *userData) {
    for (int i=0; i < MAX_HOOKS; i++) {
        struct pbw_mem_region *rgn = &cpu->exec_hooks[i];
        if (rgn->access == NULL) {
            rgn->begin = address;
            rgn->end = address + size;
            rgn->perms = PBW_MEM_EXEC;
            rgn->access = hook;
            rgn->ptr = userData;
            return i;
        }
    }
    return -PBW_ERR_HOOK_LIMIT;
}

enum loadstore_op {
    store, load, load_signed
};

void pbw_cpu_exec_loadstore(pbw_cpu cpu, uint32_t ins, uint32_t pc) {
    enum loadstore_op ls_op = load;
    pbw_mem_size size = PBW_MEM_WORD;
    int index = 1; // P
    int add = 1; // U
    int wback = 0; // W
    int immediate = 0;
    int dual = 0;
    uint32_t m = 0;
    uint32_t n;
    uint32_t t;
    uint32_t t2 = 0;
    uint32_t imm = 0;
    uint32_t shift_t = SRType_LSL;
    uint32_t shift_n = 0;
    if (!INSTRUCTION_THUMB32(ins)) {
        // 16-bit instruction
        n = (ins & 0x38) >> 3;
        t = ins & 0x07;
        switch (ins >> 9) {
            case 0x28:
                // Store: STR (register) T1
                m = (ins & 0x01C0) >> 6;
                ls_op = store;
                size = PBW_MEM_WORD;
                break;
            case 0x29:
                // Store Halfword: STRH (register) T1
                m = (ins & 0x01C0) >> 6;
                ls_op = store;
                size = PBW_MEM_HALFWORD;
                break;
            case 0x2a:
                // Store Byte: STRB (register) T1
                m = (ins & 0x01C0) >> 6;
                ls_op = store;
                size = PBW_MEM_BYTE;
                break;
            case 0x2b:
                // Load Signed Byte: LDRSB (register) T1
                m = (ins & 0x01C0) >> 6;
                ls_op = load_signed;
                size = PBW_MEM_BYTE;
                break;
            case 0x2c:
                // Load: LDR (register) T1
                m = (ins & 0x01C0) >> 6;
                ls_op = load;
                size = PBW_MEM_WORD;
                break;
            case 0x2d:
                // Load Halfword: LDRH (register) T1
                m = (ins & 0x01C0) >> 6;
                ls_op = load;
                size = PBW_MEM_HALFWORD;
                break;
            case 0x2e:
                // Load Byte: LDRB (register) T1
                m = (ins & 0x01C0) >> 6;
                ls_op = load;
                size = PBW_MEM_BYTE;
                break;
            case 0x2f:
                // Load Signed Halfword: LDRSH (register) T1
                m = (ins & 0x01C0) >> 6;
                ls_op = load_signed;
                size = PBW_MEM_HALFWORD;
                break;
            case 0x30:
            case 0x31:
            case 0x32:
            case 0x33:
                // Store: STR (immediate) T1
                imm = (ins & 0x07C0) >> 4;
                immediate = 1;
                ls_op = store;
                size = PBW_MEM_WORD;
                break;
            case 0x34:
            case 0x35:
            case 0x36:
            case 0x37:
                // Load: LDR (immediate) T1
                imm = (ins & 0x07C0) >> 4;
                immediate = 1;
                ls_op = load;
                size = PBW_MEM_WORD;
                break;
            case 0x38:
            case 0x39:
            case 0x3a:
            case 0x3b:
                // Store Byte: STRB (immediate) T1
                imm = (ins & 0x07C0) >> 6;
                immediate = 1;
                ls_op = store;
                size = PBW_MEM_BYTE;
                break;
            case 0x3c:
            case 0x3d:
            case 0x3e:
            case 0x3f:
                // Load Byte: LDRB (immediate) T1
                imm = (ins & 0x07C0) >> 6;
                immediate = 1;
                ls_op = load;
                size = PBW_MEM_BYTE;
                break;
            case 0x40:
            case 0x41:
            case 0x42:
            case 0x43:
                // Store Halfword: STRH (immediate) T1
                imm = (ins & 0x07C0) >> 5;
                immediate = 1;
                ls_op = store;
                size = PBW_MEM_HALFWORD;
                break;
            case 0x44:
            case 0x45:
            case 0x46:
            case 0x47:
                // Load Halfword: LDRH (immediate) T1
                imm = (ins & 0x07C0) >> 5;
                immediate = 1;
                ls_op = load;
                size = PBW_MEM_HALFWORD;
                break;
            case 0x48:
            case 0x49:
            case 0x4a:
            case 0x4b:
                // Store SP-relative: STR (immediate) T2
                t = (ins & 0x0700) >> 8;
                n = REG_SP;
                imm = (ins & 0xff) << 2;
                immediate = 1;
                ls_op = store;
                size = PBW_MEM_WORD;
                break;
            case 0x4c:
            case 0x4d:
            case 0x4e:
            case 0x4f:
                // Load SP-relative: LDR (immediate) T2:
                t = (ins & 0x0700) >> 8;
                n = REG_SP;
                imm = (ins & 0xff) << 2;
                immediate = 1;
                ls_op = load;
                size = PBW_MEM_WORD;
                break;
            default:
                CPU_BREAK(UNPREDICTABLE);
        }
    } else if (ins & 0x10000000) {
        // common format for instructions starting with 0b11111
        if INS_MASK(0xfe50f000, 0xf810f000) {
            // MARK: PLI, PLD
            // Unallocated memory hints
            // Unpredictable
            // Treat as NOP
            return;
        }
        // load/store type
        if ((ins & 0x100000) == 0) {
            ls_op = store;
        } else if ((ins & 0x1000000)) {
            ls_op = load_signed;
        }
        if ((ins & 0x1100000) == 0x1000000) {
            // store and load signed are mutually exclusive
            CPU_BREAK(UNDEFINED);
        }
        // source/destination
        n = (ins >> 16) & 0xf;
        t = (ins >> 12) & 0xf;
        // size
        switch ((ins >> 21) & 3) {
            case 0:
                size = PBW_MEM_BYTE;
                break;
            case 1:
                size = PBW_MEM_HALFWORD;
                break;
            case 2:
                size = PBW_MEM_WORD;
                break;
            case 3:
                CPU_BREAK(UNDEFINED);
                break;
        }
        // value
        if ((ins & 0x800000) || (n == 0xf)) {
            // 12-bit immediate
            immediate = 1;
            imm = ins & 0xfff;
            add = (n == 0xf) ? (ins & 0x800000) : 1;
        } else if (ins & 0x800) {
            // puw + immediate
            immediate = 1;
            imm = ins & 0xff;
            index = (ins & 0x400);
            add = (ins & 0x200);
            wback = (ins & 0x100);
        } else {
            // shifted offset
            immediate = 0;
            m = ins & 0xf;
            shift_n = (ins >> 4) & 0x3;
        }
    } else {
        // common format for instructions starting with 0b11101
        index = (ins & 0x1000000);
        add = (ins & 0x800000);
        wback = (ins & 0x200000);
        ls_op = (ins & 0x100000) ? load : store;
        size = PBW_MEM_WORD;
        n = (ins >> 16) & 0xf;
        t = (ins >> 12) & 0xf;
        if (index || wback) {
            // STRD, LDRD
            dual = 1;
            t2 = (ins >> 8) & 0xf;
            if (t == t2 || t == 13 || t == 15 || t2 == 13 || t2 == 15) {
                CPU_BREAK(UNPREDICTABLE);
            }
            if (wback && (n == t || n == t2)) {
                CPU_BREAK(UNPREDICTABLE);
            }
            immediate = 1;
            imm = (ins & 0xff) << 2;
        } else {
            // Exclusive access
            CPU_BREAK(NOT_IMPLEMENTED);
        }
    }
    if (ConditionPassed()) {
        uint32_t offset = immediate ? imm : pbw_cpu_alu_shift(cpu, m == REG_PC ? pc + 4 : R[m], shift_t, shift_n, APSR_C, 0);
        uint32_t reg_n = R[n];
        if (n == REG_PC) reg_n = Align(pc + 4, 4);
        uint32_t offset_addr = add ? reg_n + offset : reg_n - offset;
        uint32_t address = index ? offset_addr : reg_n;
        uint32_t data;
        switch (ls_op) {
            case store:
                data = R[t];
                if (t == REG_PC) data = pc + 4;
                pbw_cpu_mem_write(cpu, address, size, data);
                if (dual) pbw_cpu_mem_write(cpu, address+4, size, R[t2]);
                break;
            case load:
                data = pbw_cpu_mem_read(cpu, address, PBW_MEM_READ, size);
                if (t == REG_PC && (address & 3) != 0) {
                    CPU_BREAK(UNPREDICTABLE);
                } else {
                    R[t] = data;
                    if (dual) R[t2] = pbw_cpu_mem_read(cpu, address+4, PBW_MEM_READ, size);
                }
                break;
            case load_signed:
                data = pbw_cpu_mem_read(cpu, address, PBW_MEM_READ, size);
                if (size == PBW_MEM_BYTE && (data & 0x80)) {
                    data |= 0xffffff00;
                } else if (size == PBW_MEM_HALFWORD && (data & 0x8000)) {
                    data |= 0xffff0000;
                }
                R[t] = data;
                break;
        }
        if (wback) {
            R[n] = offset_addr;
        }
    }
    
}

void pbw_cpu_exec_stm(pbw_cpu cpu, uint32_t ins, uint32_t pc, uint32_t n, uint32_t registers, uint32_t wback, uint32_t db) {
    if (ConditionPassed()) {
        uint32_t address = db ? R[n] - 4*BitCount(registers) : R[n];
        for (int i=0; i <= 14; i++) {
            if (registers & (1 << i)) {
                pbw_cpu_mem_write(cpu, address, PBW_MEM_WORD, R[i]);
                address += 4;
            }
        }
        if (wback) {
            R[n] += (db ? -4 : 4) * BitCount(registers);
        }
    }
}

void pbw_cpu_exec_ldm(pbw_cpu cpu, uint32_t ins, uint32_t pc, uint32_t n, uint32_t registers, uint32_t wback, uint32_t db) {
    if (ConditionPassed()) {
        uint32_t address = db ? R[n] - 4*BitCount(registers) : R[n];
        for (int i=0; i <= 15; i++) {
            if (registers & (1 << i)) {
                R[i] = pbw_cpu_mem_read(cpu, address, PBW_MEM_READ, PBW_MEM_WORD);
                address += 4;
            }
        }
        if (wback && ((registers & (1 << n)) == 0)) {
            R[n] += (db ? -4 : 4) * BitCount(registers);
        }
    }
}

void pbw_cpu_push(pbw_cpu cpu, uint32_t val) {
    uint32_t address = cpu->reg[REG_SP] - 4;
    pbw_cpu_mem_write(cpu, address, PBW_MEM_WORD, val);
    cpu->reg[REG_SP] = address;
}

uint32_t pbw_cpu_pop(pbw_cpu cpu) {
    uint32_t val = pbw_cpu_mem_read(cpu, cpu->reg[REG_SP], PBW_MEM_READ, PBW_MEM_WORD);
    cpu->reg[REG_SP] += 4;
    return val;
}

uint32_t pbw_cpu_stack_peek(pbw_cpu cpu, uint32_t idx) {
    return pbw_cpu_mem_read(cpu, cpu->reg[REG_SP] + (4*idx), PBW_MEM_READ, PBW_MEM_WORD);
}

uint32_t pbw_cpu_push_data(pbw_cpu cpu, uint32_t val, size_t size, void *data) {
    uint32_t address = cpu->reg[REG_SP] - (uint32_t)size;
    pbw_err err = pbw_cpu_mem_write_block(cpu, address, size, data);
    if (err) {
        printf("pbw_cpu_push_data: error %d\n", err);
    }
    cpu->reg[REG_SP] = address;
    return address;
}

uint32_t pbw_cpu_pop_data(pbw_cpu cpu, size_t size, void *data) {
    uint32_t address = cpu->reg[REG_SP];
    pbw_err err = pbw_cpu_mem_read_block(cpu, address, size, data);
    if (err) {
        printf("pbw_cpu_pop_data: error %d\n", err);
    }
    cpu->reg[REG_SP] += (uint32_t)size;
    return address;
}

pbw_err pbw_cpu_mem_read_block(pbw_cpu cpu, uint32_t addr, size_t size, void *data) {
    struct pbw_mem_region *rgn = pbw_cpu_mem_region(cpu, addr, PBW_MEM_RWX);
    if (rgn == NULL || addr + size > rgn->end) {
        // out of range
        return PBW_ERR_MEM_LIMIT;
    }
    memcpy(data, rgn->ptr + (addr - rgn->begin), size);
    return PBW_ERR_OK;
}

pbw_err pbw_cpu_mem_write_block(pbw_cpu cpu, uint32_t addr, size_t size, const void *data) {
    struct pbw_mem_region *rgn = pbw_cpu_mem_region(cpu, addr, PBW_MEM_RWX);
    if (rgn == NULL || addr + size > rgn->end) {
        // out of range
        return PBW_ERR_MEM_LIMIT;
    }
    memcpy(rgn->ptr + (addr - rgn->begin), data, size);
    return PBW_ERR_OK;
}

/* dev read */

uint32_t pbw_cpu_read_word(pbw_cpu cpu, uint32_t ptr) {
    return pbw_cpu_mem_read(cpu, ptr, PBW_MEM_READ, PBW_MEM_WORD);
}

uint16_t pbw_cpu_read_halfword(pbw_cpu cpu, uint32_t ptr) {
    return pbw_cpu_mem_read(cpu, ptr, PBW_MEM_READ, PBW_MEM_HALFWORD);
}

uint8_t pbw_cpu_read_byte(pbw_cpu cpu, uint32_t ptr) {
    return pbw_cpu_mem_read(cpu, ptr, PBW_MEM_READ, PBW_MEM_BYTE);
}

const char* pbw_cpu_read_cstring(pbw_cpu cpu, uint32_t addr) {
    struct pbw_mem_region *rgn = pbw_cpu_mem_region(cpu, addr, PBW_MEM_RWX);
    if (rgn == NULL) {
        // out of range
        return NULL;
    }
    return rgn->ptr + (addr - rgn->begin);
}
