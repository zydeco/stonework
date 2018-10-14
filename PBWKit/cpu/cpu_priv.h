//
//  cpu_priv.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 15/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#ifndef cpu_priv_h
#define cpu_priv_h

#include <stdlib.h>
#include <stdio.h>
#include "cpu.h"

typedef enum {
    PBW_HOOK_TYPE_NONE = 0,
    PBW_HOOK_TYPE_PTR,
    PBW_HOOK_TYPE_MEM,
    PBW_HOOK_TYPE_FUNC,
    PBW_HOOK_TYPE_EXEC,
} pbw_hook_type;

struct pbw_mem_region {
    uint32_t begin, end;
    pbw_cpu_hook access;
    void *ptr;
    int perms;
};

#define MAX_MEM_REGIONS 16
#define MAX_HOOKS 8
#define NUM_REGISTERS 23

struct pbw_cpu {
    int running;
    pbw_err err;
    uint32_t reg[NUM_REGISTERS];
    struct pbw_mem_region mem_regions[MAX_MEM_REGIONS];
    struct pbw_mem_region exec_hooks[MAX_HOOKS];
    pbw_cpu_hook invalid_instruction, invalid_access;
    void *userData;
};

uint32_t pbw_cpu_default_hook(pbw_cpu cpu, void *userData, uint32_t addr, pbw_mem_op op, pbw_mem_size size, uint32_t value);
uint32_t pbw_cpu_mem_read(pbw_cpu cpu, uint32_t addr, pbw_mem_op op, pbw_mem_size size);
uint32_t pbw_cpu_mem_write(pbw_cpu cpu, uint32_t addr, pbw_mem_size size, uint32_t value);
uint32_t pbw_cpu_mem_access(pbw_cpu cpu, void *ptr, uint32_t offset, pbw_mem_op op, pbw_mem_size size, uint32_t value);
int pbw_cpu_exec_hooked(pbw_cpu cpu, uint32_t pc);

void pbw_cpu_exec(pbw_cpu cpu, uint32_t ins, uint32_t pc);
uint32_t pbw_cpu_get_next_instruction(pbw_cpu cpu);

// check an already fetched instruction
#define INSTRUCTION_THUMB32(x) ((x & 0xff000000) != 0)

#define INS_MASK(mask, value) ((ins & mask) == value)
#define INS_DEF(name, ...) void pbw_cpu_exec_##name (pbw_cpu cpu, uint32_t ins, uint32_t pc, ##__VA_ARGS__)
#define INS_CALL(name, ...) pbw_cpu_exec_##name (cpu, ins, pc, ##__VA_ARGS__)

INS_DEF(thumb);
INS_DEF(thumb2);
INS_DEF(thumb_misc);
INS_DEF(thumb2_misc);
#define pbw_cpu_exec_push(c,i,p,r) pbw_cpu_exec_stm(c,i,p,REG_SP,r,1,1)
#define pbw_cpu_exec_pop(c,i,p,r) pbw_cpu_exec_ldm(c,i,p,REG_SP,r,1,0)
INS_DEF(cbznz);
INS_DEF(stm, uint32_t n, uint32_t registers, uint32_t wback, uint32_t db);
INS_DEF(ldm, uint32_t n, uint32_t registers, uint32_t wback, uint32_t db);
INS_DEF(loadstore);

#endif /* cpu_priv_h */
