//
//  memory.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 03/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWRuntime.h"
#import "../../cpu/cpu.h"
#import "../api.h"
#import "weemalloc.h"
#import "PBWAddressSpace.h"

#define ReadRAMPointer(p) (p ? p - kHeapBase : 0)
#define MakeRAMPointer(p) (p ? p + kHeapBase: 0)

uint32_t pbw_api_malloc(pbw_ctx ctx, uint32_t size) {
    void *heap = ctx->heapPtr;
    uint32_t ptr = weemalloc(heap, size);
    return MakeRAMPointer(ptr);
}

uint32_t pbw_api_calloc(pbw_ctx ctx, uint32_t count, uint32_t size) {
    void *heap = ctx->heapPtr;
    uint32_t ptr = weecalloc(heap, count, size);
    return MakeRAMPointer(ptr);
}

uint32_t pbw_api_realloc(pbw_ctx ctx, uint32_t ptr, uint32_t size) {
    void *heap = ctx->heapPtr;
    uint32_t newPtr = weerealloc(heap, ptr, size);
    return MakeRAMPointer(newPtr);
}

uint32_t pbw_api_free(pbw_ctx ctx, uint32_t ptr) {
    void *heap = ctx->heapPtr;
    weefree(heap, ReadRAMPointer(ptr));
    return 0;
}

uint32_t pbw_api_memcpy(pbw_ctx ctx, uint32_t dst, uint32_t src, uint32_t size) {
    memcpy(pbw_ctx_get_pointer(ctx, dst), pbw_ctx_get_pointer(ctx, src), size);
    return dst;
}

uint32_t pbw_api_memmove(pbw_ctx ctx, uint32_t dst, uint32_t src, uint32_t size) {
    memmove(pbw_ctx_get_pointer(ctx, dst), pbw_ctx_get_pointer(ctx, src), size);
    return dst;
}

uint32_t pbw_api_memset(pbw_ctx ctx, uint32_t ptr, uint32_t c, uint32_t size) {
    c &= 0xff;
    memset(pbw_ctx_get_pointer(ctx, ptr), c, size);
    return ptr;
}
