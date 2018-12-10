//
//  string.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 13/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWRuntime.h"
#import "../../cpu/cpu.h"
#import "../api.h"
#import <string.h>
#import "NSString+PBWRuntime.h"

uint32_t pbw_api_strcmp(pbw_ctx ctx, uint32_t s1, uint32_t s2) {
    return strcmp(pbw_ctx_get_pointer(ctx, s1), pbw_ctx_get_pointer(ctx, s2));
}

uint32_t pbw_api_strncmp(pbw_ctx ctx, uint32_t s1, uint32_t s2, uint32_t n) {
    return strncmp(pbw_ctx_get_pointer(ctx, s1), pbw_ctx_get_pointer(ctx, s2), n);
}

uint32_t pbw_api_strcpy(pbw_ctx ctx, uint32_t dstPtr, uint32_t srcPtr) {
    if (dstPtr == srcPtr) {
        return dstPtr;
    }
    const char *src = pbw_ctx_get_pointer(ctx, srcPtr);
    memmove(pbw_ctx_get_pointer(ctx, dstPtr), src, 1+strlen(src));
    return dstPtr;
}

uint32_t pbw_api_strncpy(pbw_ctx ctx, uint32_t dst, uint32_t src, uint32_t n) {
    strncpy(pbw_ctx_get_pointer(ctx, dst), pbw_ctx_get_pointer(ctx, src), n);
    return dst;
}

uint32_t pbw_api_strcat(pbw_ctx ctx, uint32_t dst, uint32_t src) {
    strcat(pbw_ctx_get_pointer(ctx, dst), pbw_ctx_get_pointer(ctx, src));
    return dst;
}

uint32_t pbw_api_strncat(pbw_ctx ctx, uint32_t dst, uint32_t src, uint32_t n) {
    strncat(pbw_ctx_get_pointer(ctx, dst), pbw_ctx_get_pointer(ctx, src), n);
    return dst;
}

uint32_t pbw_api_strlen(pbw_ctx ctx, uint32_t str) {
    return (uint32_t)strlen(pbw_ctx_get_pointer(ctx, str));
}

uint32_t pbw_api_snprintf(pbw_ctx ctx, uint32_t str, uint32_t n, uint32_t fmt) {
    NSString *string = [NSString stringWithPBWContext:ctx formatArgument:2];
    char *dst = pbw_ctx_get_pointer(ctx, str);
    NSUInteger bytesWritten;
    [string getBytes:dst maxLength:n-1 usedLength:&bytesWritten encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, string.length) remainingRange:NULL];
    dst[bytesWritten] = '\0';
    return (uint32_t)bytesWritten;
}
