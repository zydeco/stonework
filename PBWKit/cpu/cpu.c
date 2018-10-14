//
//  cpu.c
//  Stonework
//
//  Created by Jesús A. Álvarez on 15/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#include "cpu_priv.h"
#include <capstone/capstone.h>
#include <stdarg.h>

pbw_cpu pbw_cpu_init(pbw_cpu_hook invalid_access_hook, pbw_cpu_hook invalid_instruction_hook, void *userData) {
    pbw_cpu cpu = calloc(1, sizeof(struct pbw_cpu));
    cpu->invalid_access = invalid_access_hook ?: pbw_cpu_default_hook;
    cpu->invalid_instruction = invalid_instruction_hook ?: pbw_cpu_default_hook;
    pbw_cpu_reset(cpu);
    return cpu;
}

void pbw_cpu_reset(pbw_cpu cpu) {
    for (int i=0; i <= 22; i++) {
        cpu->reg[i] = 0;
    }
    cpu->reg[REG_EPSR] = 0x1000000; // Thumb mode
    cpu->reg[REG_CONTROL] = 1; // Unprivileged thread mode, SP_main stack
}

void pbw_cpu_destroy(pbw_cpu cpu) {
    free(cpu);
}

uint32_t pbw_cpu_reg_get(pbw_cpu cpu, int reg) {
    if (reg < sizeof(cpu->reg) / sizeof(cpu->reg[0])) {
        return cpu->reg[reg];
    } else {
        return 0;
    }
}

void pbw_cpu_reg_set(pbw_cpu cpu, int reg, uint32_t val) {
    if (reg < sizeof(cpu->reg) / sizeof(cpu->reg[0])) {
        cpu->reg[reg] = val;
    }
}

// default invalid access/instruction hook

uint32_t pbw_cpu_default_hook(pbw_cpu cpu, void *userData, uint32_t addr, pbw_mem_op op, pbw_mem_size size, uint32_t value) {
    if (op == PBW_MEM_EXEC) {
        printf("invalid instruction: %x at 0x%08x\n", value, addr);
        pbw_cpu_stop(cpu, PBW_ERR_INVALID_INSTRUCTION);
    } else {
        if (op == PBW_MEM_WRITE) {
            printf("invalid write: %x at 0x%08x\n", value, addr);
        } else {
            printf("invalid %s: 0x%08x\n", value ? "fetch" : "read", addr);
        }

        pbw_cpu_stop(cpu, PBW_ERR_INVALID_ACCESS);
    }
    return 0;
}

pbw_err pbw_cpu_resume(pbw_cpu cpu) {
    return pbw_cpu_resume_until(cpu, 0);
}

#define PRINT_DISASSEMBLY

pbw_err pbw_cpu_resume_until(pbw_cpu cpu, uint32_t stop_address) {
#if defined(PRINT_DISASSEMBLY)
    csh capstone;
    uint8_t buf[4];
    const uint8_t *cs_code;
    size_t cs_size;
    uint64_t cs_addr;
    cs_insn *cs_insn;
    cs_err err = cs_open(CS_ARCH_ARM, CS_MODE_THUMB, &capstone);
    if (err != CS_ERR_OK) {
        printf("error: %s\n", cs_strerror(err));
        abort();
    }
    cs_insn = cs_malloc(capstone);
#endif
    
    cpu->running = 1;
    for (;;) {
        uint32_t pc = cpu->reg[REG_PC] & ~1;
        if (stop_address && pc == stop_address) {
            // execution done
            cpu->err = PBW_ERR_OK;
            break;
        }
        if (pbw_cpu_exec_hooked(cpu, pc)) {
            if (cpu->running) {
                continue;
            } else {
                break;
            }
        }
        uint32_t ins = pbw_cpu_get_next_instruction(cpu);
#if defined(PRINT_DISASSEMBLY)
        cs_addr = pc & ~1;
        cs_code = buf;
        cs_size = INSTRUCTION_THUMB32(ins) ? 4 : 2;
        OSWriteLittleInt32(buf, 0, pbw_cpu_mem_read(cpu, (uint32_t)cs_addr, PBW_MEM_READ, PBW_MEM_WORD));
        if (cs_disasm_iter(capstone, &cs_code, &cs_size, &cs_addr, cs_insn)) {
            printf("0x%" PRIx64 ":\t%-12s%s\n", cs_insn->address, cs_insn->mnemonic, cs_insn->op_str);
        } else if (!INSTRUCTION_THUMB32(ins)) {
            printf("0x%" PRIx64 ":\t%-12s0x%" PRIx16 "\n", (uint64_t)cpu->reg[REG_PC], "dw", (uint16_t)ins);
        } else {
            printf("0x%" PRIx64 ":\t%-12s0x%" PRIx32 "\n", (uint64_t)cpu->reg[REG_PC], "dd", ins);
        }
#endif
        if (!cpu->running) break;
        pbw_cpu_exec(cpu, ins, pc);
        if (!cpu->running) break;
    }
#if defined(PRINT_DISASSEMBLY)
    cs_free(cs_insn, 1);
    cs_close(&capstone);
#endif
    return cpu->err;
}

pbw_err pbw_cpu_stop(pbw_cpu cpu, pbw_err error) {
    cpu->running = 0;
    cpu->err = error;
    return PBW_ERR_OK;
}

int pbw_cpu_exec_hooked(pbw_cpu cpu, uint32_t pc) {
    for (int i=0; i < MAX_HOOKS; i++) {
        struct pbw_mem_region *rgn = &cpu->exec_hooks[i];
        if (rgn->access == NULL) break;
        if ((pc >= rgn->begin) && (pc < rgn->end)) {
            // run hook
            rgn->access(cpu, rgn->ptr, pc - rgn->begin, PBW_MEM_EXEC, 0, pc);
            return 1;
        }
    }
    return 0;
}

pbw_err pbw_cpu_call(pbw_cpu cpu, uint32_t address, uint32_t return_value[4], int nargs, ...) {
    // save state
    uint32_t saved_registers[NUM_REGISTERS];
    int was_running = cpu->running;
    for(int i=0; i < NUM_REGISTERS; i++) saved_registers[i] = cpu->reg[i];
    
    // add arguments
    if (nargs > 4) {
        // extra arguments should be in stack in reverse order
        return PBW_ERR_NOT_IMPLEMENTED;
    }
    int next_arg = 0;
    va_list vl;
    va_start(vl, nargs);
    for(int i=0; i < nargs; i++) {
        uint32_t arg = va_arg(vl, uint32_t);
        cpu->reg[next_arg++] = arg;
    }
    va_end(vl);
    
    // call procedure
    uint32_t return_address = 0xE000ED3C;
    pbw_cpu_reg_set(cpu, REG_PC, address);
    pbw_cpu_reg_set(cpu, REG_LR, return_address);
    pbw_err err = pbw_cpu_resume_until(cpu, return_address);
    if (err) {
        printf("error in subroutine call: %d\n", err);
    }
    
    if (return_value) {
        for(int i=0; i < 4; i++) return_value[i] = cpu->reg[i];
    }
    
    // restore state
    for(int i=0; i < NUM_REGISTERS; i++) cpu->reg[i] = saved_registers[i];
    cpu->running = was_running;
    
    return err;
}
