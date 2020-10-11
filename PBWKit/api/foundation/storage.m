//
//  storage.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 10/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWRuntime.h"

#define PERSIST_DATA_MAX_LENGTH 256

uint32_t pbw_api_persist_exists(pbw_ctx ctx, uint32_t key) {
    return [ctx->runtime.persistentStorage objectForKey:@(key)] ? PBW_S_TRUE : PBW_S_FALSE;
}

uint32_t pbw_api_persist_get_size(pbw_ctx ctx, uint32_t key) {
    id value = [ctx->runtime.persistentStorage objectForKey:@(key)];
    if (value == nil) {
        return PBW_E_DOES_NOT_EXIST;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        return 4;
    } else if ([value isKindOfClass:[NSString class]]) {
        return 1+(uint32_t)[value lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    } else if ([value isKindOfClass:[NSData class]]) {
        return (uint32_t)[value length];
    } else {
        return PBW_E_ERROR;
    }
}

uint32_t pbw_api_persist_read_bool(pbw_ctx ctx, uint32_t key) {
    id value = [ctx->runtime.persistentStorage objectForKey:@(key)];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value boolValue] ? PBW_S_TRUE : PBW_S_FALSE;
    } else {
        return PBW_S_FALSE;
    }
}

uint32_t pbw_api_persist_read_int(pbw_ctx ctx, uint32_t key) {
    id value = [ctx->runtime.persistentStorage objectForKey:@(key)];
    if ([value isKindOfClass:[NSNumber class]]) {
        return (uint32_t)[value intValue];
    } else {
        return 0;
    }
}

uint32_t pbw_api_persist_read_data(pbw_ctx ctx, uint32_t key, uint32_t buffer, int32_t buffer_size) {
    id value = [ctx->runtime.persistentStorage objectForKey:@(key)];
    if ([value isKindOfClass:[NSData class]]) {
        uint32_t length = MIN(buffer_size, (uint32_t)[value length]);
        void *buf = pbw_ctx_get_pointer(ctx, buffer);
        memcpy(buf, [value bytes], length);
        return length;
    } else if ([value isKindOfClass:[NSString class]]) {
        char *buf = pbw_ctx_get_pointer(ctx, buffer);
        NSUInteger usedLength;
        [value getBytes:buf maxLength:buffer_size-1 usedLength:&usedLength encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, [value length]) remainingRange:NULL];
        buf[usedLength] = 0;
        return (uint32_t)usedLength;
    } else {
        return PBW_E_DOES_NOT_EXIST;
    }
}

uint32_t pbw_api_persist_read_string(pbw_ctx ctx, uint32_t key, uint32_t buffer, int32_t buffer_size) {
    return pbw_api_persist_read_data(ctx, key, buffer, buffer_size);
}

uint32_t pbw_api_persist_write_bool(pbw_ctx ctx, uint32_t key, uint32_t value) {
    [ctx->runtime.persistentStorage setObject:@(value ? YES : NO) forKey:@(key)];
    [ctx->runtime savePersistentStorage];
    return 4;
}

uint32_t pbw_api_persist_write_int(pbw_ctx ctx, uint32_t key, int32_t value) {
    [ctx->runtime.persistentStorage setObject:@(value) forKey:@(key)];
    [ctx->runtime savePersistentStorage];
    return 4;
}

uint32_t pbw_api_persist_write_data(pbw_ctx ctx, uint32_t key, uint32_t data, int32_t size) {
    if (size > PERSIST_DATA_MAX_LENGTH) {
        return PBW_E_OUT_OF_STORAGE;
    }
    NSData *value = [NSData dataWithBytes:pbw_ctx_get_pointer(ctx, data) length:size];
    [ctx->runtime.persistentStorage setObject:value forKey:@(key)];
    [ctx->runtime savePersistentStorage];
    return size;
}

uint32_t pbw_api_persist_write_string(pbw_ctx ctx, uint32_t key, uint32_t cstring) {
    NSString *value = [NSString stringWithCString:pbw_ctx_get_pointer(ctx, cstring) encoding:NSUTF8StringEncoding];
    uint32_t size = 1 + (uint32_t)[value lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    if (size > PERSIST_DATA_MAX_LENGTH) {
        return PBW_E_OUT_OF_STORAGE;
    }
    [ctx->runtime.persistentStorage setObject:value forKey:@(key)];
    [ctx->runtime savePersistentStorage];
    return size;
}

uint32_t pbw_api_persist_delete(pbw_ctx ctx, uint32_t key) {
    [ctx->runtime.persistentStorage removeObjectForKey:@(key)];
    [ctx->runtime savePersistentStorage];
    return PBW_S_SUCCESS;
}
