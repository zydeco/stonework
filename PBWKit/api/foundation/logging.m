//
//  logging.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 13/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../../cpu/cpu.h"
#import "../api.h"
#import "PBWRuntime.h"
#import "NSString+PBWRuntime.h"

uint32_t pbw_api_app_log(pbw_ctx ctx, uint32_t log_level, uint32_t filename_ptr, uint32_t line_number, uint32_t fmt_ptr) {
    // rest of args are on stack
    NSString *string = [NSString stringWithPBWContext:ctx formatArgument:3];
    printf("[%d] %s:%d: %s\n", log_level, pbw_cpu_read_cstring(ctx->cpu, filename_ptr), line_number, string.UTF8String);
    return 0;
}
