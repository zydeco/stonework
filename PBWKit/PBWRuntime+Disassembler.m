//
//  PBWRuntime+Disassembler.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 30/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWRuntime+Disassembler.h"
#import <capstone/capstone.h>
#import "PBWApp.h"
#import "PBWAddressSpace.h"

@implementation PBWRuntime (Disassembler)

- (NSString *)disassemble {
    csh handle;
    cs_insn *insn;
    size_t count;
    cs_err err = cs_open(CS_ARCH_ARM, CS_MODE_THUMB, &handle);
    if (err != CS_ERR_OK) {
        return nil;
    }
    
    NSData *appImage = self.app.appBinary;
    uint32_t appStart = OSReadLittleInt32(appImage.bytes, 0x10);
    uint32_t appBase = kAppBase;
    count = cs_disasm(handle, appImage.bytes + 0x82, appImage.length - 0x82, appBase + 0x82, 0, &insn);
    if (count == 0) {
        cs_close(&handle);
        return nil;
    }
    
    NSLog(@"Disassembled %d instructions", (int)count);
    NSMutableString *result = [NSMutableString stringWithCapacity:count * 32];
    [result appendFormat:@"; %@\n", self.app.appName];
    char buf[16];
    for (size_t i=0; i < count; i++) {
        if (insn[i].size == 2) {
            sprintf(buf, "    %02x%02x", insn[i].bytes[0], insn[i].bytes[1]);
        } else {
            sprintf(buf, "%02x%02x%02x%02x", insn[i].bytes[0], insn[i].bytes[1], insn[i].bytes[2], insn[i].bytes[3]);
        }
        if (insn[i].address == appBase + appStart) {
            [result appendFormat:@"        main:\n"];
        }
        [result appendFormat:@"0x%05x: %s %s %s\n", (int)insn[i].address, buf, insn[i].mnemonic, insn[i].op_str];
    }
    cs_free(insn, count);
    cs_close(&handle);
    return result;
}

@end
