//
//  PBWCPUTests.m
//  PBWCPUTests
//
//  Created by Jesús A. Álvarez on 21/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "../PBWKit/cpu/cpu.h"

@interface PBWCPUTests : XCTestCase

@end

static NSExceptionName PBWInvalidAccessException = @"PBWInvalidAccessException";
static NSExceptionName PBWInvalidInstructionException = @"PBWInvalidInstructionException";

uint32_t on_invalid_access(pbw_cpu cpu, void *userData, uint32_t addr, pbw_mem_op op, pbw_mem_size size, uint32_t value) {
    @throw [NSException exceptionWithName:PBWInvalidAccessException reason:nil userInfo:@{@"address": @(addr),
                                                                                          @"op": @(op),
                                                                                          @"size": @(size),
                                                                                          @"value": @(value)
                                                                                          }];
}

uint32_t on_invalid_instruction(pbw_cpu cpu, void *userData, uint32_t addr, pbw_mem_op op, pbw_mem_size size, uint32_t value) {
    @throw [NSException exceptionWithName:PBWInvalidInstructionException reason:nil userInfo:@{@"address": @(addr),
                                                                                               @"instruction": @(value)
                                                                                               }];
}

#define kRAMBase 0x1000
#define kRAMSize 0x10000

#define SetReg(r, v) pbw_cpu_reg_set(cpu, r, v)
#define SetRegs(start, ...) { uint32_t values[] = {__VA_ARGS__}; for(int i=0; i < sizeof(values)/sizeof(values[0]);i++) { SetReg(start+i, values[i]); }}
#define ChkReg(r, v) XCTAssertEqual(v, pbw_cpu_reg_get(cpu, r), @"r%d", r)
#define ChkRegs(start, ...) { uint32_t values[] = {__VA_ARGS__}; for(int i=0; i < sizeof(values)/sizeof(values[0]);i++) { ChkReg(start+i, values[i]); }}


@implementation PBWCPUTests
{
    pbw_cpu cpu;
    uint8_t *ram;
    uint32_t r0, r1, r2, r3, r4, r5, r6, r7;
    uint32_t r8, r9, r10, r11, r12, sp, lr, pc;
    uint32_t apsr, ipsr, epsr;
}

- (void)setUp {
    cpu = pbw_cpu_init(on_invalid_access, on_invalid_instruction, NULL);
    XCTAssert(cpu != NULL, @"CPU initialized");
    ram = calloc(1, kRAMSize);
    XCTAssert(ram != NULL, @"RAM allocated");
    int mem = pbw_cpu_mem_map_ptr(cpu, kRAMBase, kRAMSize, PBW_MEM_RWX, ram);
    XCTAssert(mem >= 0, @"RAM mapped");
    pbw_cpu_reg_set(cpu, REG_PC, kRAMBase);
    pbw_cpu_reg_set(cpu, REG_SP, kRAMBase + kRAMSize); // top of RAM
    [self readRegisters];
}

- (void)writeRegisters {
    pbw_cpu_reg_set(cpu, 0, r0);
    pbw_cpu_reg_set(cpu, 1, r1);
    pbw_cpu_reg_set(cpu, 2, r2);
    pbw_cpu_reg_set(cpu, 3, r3);
    pbw_cpu_reg_set(cpu, 4, r4);
    pbw_cpu_reg_set(cpu, 5, r5);
    pbw_cpu_reg_set(cpu, 6, r6);
    pbw_cpu_reg_set(cpu, 7, r7);
    pbw_cpu_reg_set(cpu, 8, r8);
    pbw_cpu_reg_set(cpu, 9, r9);
    pbw_cpu_reg_set(cpu, 10, r10);
    pbw_cpu_reg_set(cpu, 11, r11);
    pbw_cpu_reg_set(cpu, 12, r12);
    pbw_cpu_reg_set(cpu, REG_SP, sp);
    pbw_cpu_reg_set(cpu, REG_LR, lr);
    pbw_cpu_reg_set(cpu, REG_PC, pc);
    pbw_cpu_reg_set(cpu, REG_APSR, apsr);
    pbw_cpu_reg_set(cpu, REG_IPSR, ipsr);
    pbw_cpu_reg_set(cpu, REG_EPSR, epsr);
}

- (void)readRegisters {
    r0 = pbw_cpu_reg_get(cpu, 0);
    r1 = pbw_cpu_reg_get(cpu, 1);
    r2 = pbw_cpu_reg_get(cpu, 2);
    r3 = pbw_cpu_reg_get(cpu, 3);
    r4 = pbw_cpu_reg_get(cpu, 4);
    r5 = pbw_cpu_reg_get(cpu, 5);
    r6 = pbw_cpu_reg_get(cpu, 6);
    r7 = pbw_cpu_reg_get(cpu, 7);
    r8 = pbw_cpu_reg_get(cpu, 8);
    r9 = pbw_cpu_reg_get(cpu, 9);
    r10 = pbw_cpu_reg_get(cpu, 10);
    r11 = pbw_cpu_reg_get(cpu, 11);
    r12 = pbw_cpu_reg_get(cpu, 12);
    sp = pbw_cpu_reg_get(cpu, REG_SP);
    lr = pbw_cpu_reg_get(cpu, REG_LR);
    pc = pbw_cpu_reg_get(cpu, REG_PC);
    apsr = pbw_cpu_reg_get(cpu, REG_APSR);
    ipsr = pbw_cpu_reg_get(cpu, REG_IPSR);
    epsr = pbw_cpu_reg_get(cpu, REG_EPSR);
}

- (void)tearDown {
    pbw_cpu_destroy(cpu);
    free(ram);
}

#define Program(x) memcpy(ram, x, sizeof(x)-1); memcpy(ram+sizeof(x)-1, "\x30\xbf", 2);
#define Run(x) [self writeRegisters]; Program(x); XCTAssertEqual(pbw_cpu_resume(cpu), PBW_ERR_WAIT_FOR_INTERRUPT, @"Execution ended"); [self readRegisters];

- (void)testAdd {
    r2 = 1234;
    r3 = 3456;
    Run("\xd1\x18"); // adds r1,r2,r3
    XCTAssertEqual(r1, 4690);
    XCTAssertFalse(apsr & APSR_MASK_V, "no overflow");
}

- (void)testAddOverflow {
    r2 = 0x80000000;
    r3 = 0x80000000;
    Run("\xd1\x18"); // adds r1,r2,r3
    XCTAssertEqual(r1, 0);
    XCTAssert(apsr & APSR_MASK_V, "overflow");
}

@end
