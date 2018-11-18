//
//  NSString+PBWRuntime.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 17/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "NSString+PBWRuntime.h"


@implementation NSString (PBWRuntime)

+ (instancetype)stringWithPBWContext:(pbw_ctx)ctx formatArgument:(int)fmtArg {
    uint32_t fmt_ptr = PROC_ARG(fmtArg);
    NSString *baseFormatString = @(pbw_cpu_read_cstring(ctx->cpu, fmt_ptr));
    NSScanner *scanner = [NSScanner scannerWithString:baseFormatString];
    scanner.charactersToBeSkipped = nil;
    scanner.caseSensitive = YES;
    
    NSMutableString *string = [NSMutableString stringWithCapacity:baseFormatString.length];
    NSString *token = nil;
    int arg = fmtArg + 1;
    
    while (!scanner.atEnd) {
        if ([baseFormatString characterAtIndex:scanner.scanLocation] != '%') {
            [scanner scanUpToString:@"%" intoString:&token];
            [string appendString:token];
            if (scanner.atEnd) break;
        }
        scanner.scanLocation += 1;
        // scan token
        unichar nextChar = [baseFormatString characterAtIndex:scanner.scanLocation];
        if (nextChar == '%') {
            [string appendString:@"%"];
            scanner.scanLocation += 1;
            continue;
        }
        if (nextChar == 'h' || nextChar == 'l') {
            // length specifier
            // doesn't matter since everything is promoted to 32 bits
            scanner.scanLocation += 1;
            nextChar = [baseFormatString characterAtIndex:scanner.scanLocation];
        }
        // argument
        switch (nextChar) {
            case 'd':
            case 'i': // Signed decimal
                [string appendFormat:@"%d", (int32_t)PROC_ARG(arg)];
                break;
            case 'u': // Unsigned decimal
                [string appendFormat:@"%u", PROC_ARG(arg)];
                break;
            case 'o': // Unsigned octal
                [string appendFormat:@"%o", PROC_ARG(arg)];
                break;
            case 'x': // Unsigned hex
                [string appendFormat:@"%x", PROC_ARG(arg)];
                break;
            case 'X': // Unsigned hex (uppercase)
                [string appendFormat:@"%x", PROC_ARG(arg)];
                break;
            case 'c': // Character
                [string appendFormat:@"%c", PROC_ARG(arg)];
                break;
            case 's': // String
                [string appendFormat:@"%s", pbw_ctx_get_pointer(ctx, PROC_ARG(arg))];
                break;
            case 'p': // String
                [string appendFormat:@"0x%08x", PROC_ARG(arg)];
                break;
            default:
                break;
        }
        arg++;
        scanner.scanLocation += 1;
    }
    [string appendString:[scanner.string substringFromIndex:scanner.scanLocation]];
    return string;
}

@end
