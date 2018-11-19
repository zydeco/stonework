//
//  resources.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 18/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../../cpu/cpu.h"
#import "../api.h"
#import "PBWRuntime.h"
#import "PBWApp.h"

uint32_t pbw_api_resource_get_handle(pbw_ctx ctx, uint32_t resource_id) {
    NSData *resource = [ctx->runtime.app resourceWithID:resource_id];
    return resource ? resource_id : 0;
}

uint32_t pbw_api_resource_size(pbw_ctx ctx, uint32_t handle) {
    NSData *resource = [ctx->runtime.app resourceWithID:handle];
    return (uint32_t)resource.length;
}

uint32_t pbw_api_resource_load(pbw_ctx ctx, uint32_t handle, uint32_t buffer, uint32_t max_length) {
    NSData *resource = [ctx->runtime.app resourceWithID:handle];
    NSUInteger bytesToCopy = MIN(resource.length, max_length);
    [resource getBytes:pbw_ctx_get_pointer(ctx, buffer) length:bytesToCopy];
    return (uint32_t)bytesToCopy;
}

uint32_t pbw_api_resource_load_byte_range(pbw_ctx ctx, uint32_t handle, uint32_t start_offset, uint32_t buffer, uint32_t num_bytes) {
    NSData *resource = [ctx->runtime.app resourceWithID:handle];
    if (start_offset >= resource.length) {
        return 0;
    }
    NSRange bytesToCopy = NSMakeRange(start_offset, MIN(resource.length - start_offset, num_bytes));
    [resource getBytes:pbw_ctx_get_pointer(ctx, buffer) range:bytesToCopy];
    return (uint32_t)bytesToCopy.length;
}
