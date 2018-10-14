//
//  cpu.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 15/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#ifndef cpu_h
#define cpu_h

#include <stdint.h>

#define REG_SP 13
#define REG_LR 14
#define REG_PC 15
#define REG_APSR 16
#define REG_IPSR 17
#define REG_EPSR 18
#define REG_PRIMASK 19
#define REG_BASEPRI 20
#define REG_FAULTMASK 21
#define REG_CONTROL 22

#define APSR_MASK_N 0x80000000
#define APSR_MASK_Z 0x40000000
#define APSR_MASK_C 0x20000000
#define APSR_MASK_V 0x10000000
#define APSR_MASK_Q 0x08000000
#define EPSR_MASK_IT 0x0600FC00

typedef enum {
    PBW_MEM_READ    = 1 << 0,
    PBW_MEM_WRITE   = 1 << 1,
    PBW_MEM_EXEC    = 1 << 2,
    
    PBW_MEM_RW      = 3,
    PBW_MEM_RX      = 5,
    PBW_MEM_RWX     = 7
} pbw_mem_op;

typedef enum {
    PBW_MEM_BYTE,
    PBW_MEM_HALFWORD,
    PBW_MEM_WORD
} pbw_mem_size;

typedef enum {
    PBW_ERR_OK,
    PBW_ERR_INVALID_ACCESS,
    PBW_ERR_INVALID_INSTRUCTION,
    PBW_ERR_NOT_IMPLEMENTED,
    PBW_ERR_UNDEFINED,
    PBW_ERR_UNPREDICTABLE,
    PBW_ERR_BREAKPOINT,
    PBW_ERR_YIELD,
    PBW_ERR_WAIT_FOR_EVENT,
    PBW_ERR_WAIT_FOR_INTERRUPT,
    PBW_ERR_SEND_EVENT,
    PBW_ERR_MEM_LIMIT,
    PBW_ERR_HOOK_LIMIT,
    PBW_ERR_OVERLAP,
} pbw_err;

typedef struct pbw_cpu* pbw_cpu;
typedef uint32_t (*pbw_cpu_hook)(pbw_cpu cpu, void *userData, uint32_t addr, pbw_mem_op op, pbw_mem_size size, uint32_t value);

// cpu lifetime
pbw_cpu pbw_cpu_init(pbw_cpu_hook invalid_access_hook, pbw_cpu_hook invalid_instruction_hook, void *userData);
void pbw_cpu_reset(pbw_cpu cpu);
pbw_err pbw_cpu_resume(pbw_cpu cpu);
pbw_err pbw_cpu_resume_until(pbw_cpu cpu, uint32_t address);
pbw_err pbw_cpu_stop(pbw_cpu cpu, pbw_err err);
void pbw_cpu_destroy(pbw_cpu cpu);

// memory access
uint32_t pbw_cpu_mem_read(pbw_cpu cpu, uint32_t addr, pbw_mem_op op, pbw_mem_size size);
uint32_t pbw_cpu_mem_write(pbw_cpu cpu, uint32_t addr, pbw_mem_size size, uint32_t value);
// must be within block, ignores permissions
pbw_err pbw_cpu_mem_read_block(pbw_cpu cpu, uint32_t address, size_t size, void *data);
pbw_err pbw_cpu_mem_write_block(pbw_cpu cpu, uint32_t address, size_t size, void *data);
uint32_t pbw_cpu_read_word(pbw_cpu cpu, uint32_t ptr);
uint16_t pbw_cpu_read_halfword(pbw_cpu cpu, uint32_t ptr);
uint8_t pbw_cpu_read_byte(pbw_cpu cpu, uint32_t ptr);
const char* pbw_cpu_read_cstring(pbw_cpu cpu, uint32_t addr);

// push/pop value
uint32_t pbw_cpu_stack_peek(pbw_cpu cpu, uint32_t idx);
void pbw_cpu_push(pbw_cpu cpu, uint32_t val);
uint32_t pbw_cpu_pop(pbw_cpu cpu);
// push/pop data: returns pointer to data, caller responsible for alignment
uint32_t pbw_cpu_push_data(pbw_cpu cpu, uint32_t val, size_t size, void *data);
uint32_t pbw_cpu_pop_data(pbw_cpu cpu, size_t size, void *data);
// call subroutine with up to 4 arguments: caller handles ABI details
pbw_err pbw_cpu_call(pbw_cpu cpu, uint32_t address, uint32_t return_value[4], int nargs, ...);

// register access
uint32_t pbw_cpu_reg_get(pbw_cpu cpu, int reg);
void pbw_cpu_reg_set(pbw_cpu cpu, int reg, uint32_t val);

// memory mapping & hooks
// returns memory map ID (>=0) on success, -error on failure
// memory regions and hooks can overlap each other, but not their own kind
// caller owns the memory, should free it when cpu is done
int pbw_cpu_mem_map_ptr(pbw_cpu cpu, uint32_t address, uint32_t size, int perms, void *ptr);
// hooks are called with address relative to region
int pbw_cpu_mem_map_func(pbw_cpu cpu, uint32_t address, uint32_t size, int perms, pbw_cpu_hook hook, void *userData);
int pbw_cpu_hook_exec(pbw_cpu cpu, uint32_t address, uint32_t size, pbw_cpu_hook hook, void *userData);

int pbw_cpu_disas(uint32_t ins, char *buf, size_t size, uint8_t itstate);

#endif /* cpu_h */
