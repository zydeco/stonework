//
//  PBWBitmapLayer.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 18/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWBitmapLayer.h"
#import "PBWRuntime.h"
#import "../../cpu/cpu.h"
#import "../api.h"
#import "PBWGraphics.h"
#import "PBWWindow.h"
#import "PBWBitmap.h"
#import "PBWGraphicsContext.h"

uint32_t pbw_api_bitmap_layer_create(pbw_ctx ctx, ARG_GRECT(frame)) {
    GRect frame = UNPACK_GRECT(frame);
    PBWBitmapLayer *layer = [[PBWBitmapLayer alloc] initWithRuntime:ctx->runtime frame:frame dataSize:0];
    return layer.tag;
}

uint32_t pbw_api_bitmap_layer_destroy(pbw_ctx ctx, uint32_t layerTag) {
    PBWBitmapLayer *layer = ctx->runtime.objects[@(layerTag)];
    [layer destroy];
    return 0;
}

uint32_t pbw_api_bitmap_layer_get_layer(pbw_ctx ctx, uint32_t layerTag) {
    return layerTag;
}

uint32_t pbw_api_bitmap_layer_get_bitmap(pbw_ctx ctx, uint32_t layerTag) {
    PBWBitmapLayer *layer = ctx->runtime.objects[@(layerTag)];
    return layer.bitmap;
}

uint32_t pbw_api_bitmap_layer_set_bitmap(pbw_ctx ctx, uint32_t layerTag, uint32_t bitmap) {
    PBWBitmapLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.bitmap = bitmap;
    [layer markDirty];
    return 0;
}

uint32_t pbw_api_bitmap_layer_set_alignment(pbw_ctx ctx, uint32_t layerTag, uint32_t alignment) {
    PBWBitmapLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.alignment = alignment & 0xff;
    [layer markDirty];
    return 0;
}

uint32_t pbw_api_bitmap_layer_set_background_color(pbw_ctx ctx, uint32_t layerTag, uint32_t color) {
    PBWBitmapLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.backgroundColor = GColor(color & 0xff);
    [layer markDirty];
    return 0;
}

uint32_t pbw_api_bitmap_layer_set_background_color_2bit(pbw_ctx ctx, uint32_t layerTag, uint32_t color) {
    PBWBitmapLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.backgroundColor = GColorFrom2Bit(color & 0xff);
    [layer markDirty];
    return 0;
}

uint32_t pbw_api_bitmap_layer_set_compositing_mode(pbw_ctx ctx, uint32_t layerTag, uint32_t mode) {
    PBWBitmapLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.compositingMode = mode & 0xff;
    [layer markDirty];
    return 0;
}

@implementation PBWBitmapLayer

- (instancetype)initWithRuntime:(PBWRuntime *)rt frame:(GRect)frame dataSize:(size_t)dataSize {
    if (self = [super initWithRuntime:rt frame:frame dataSize:dataSize]) {
        _backgroundColor = GColorWhite;
    }
    return self;
}

- (void)drawInContext:(CGContextRef)cg {
    pbw_ctx ctx = _runtime.runtimeContext;
    CGContextSetFillColorWithColor(cg, PBWGraphicsCGColor[_backgroundColor.argb]);
    CGContextFillRect(cg, CGRectFromGRect(self.bounds));
    if (_bitmap) {
        PBWBitmap *bitmap = ctx->runtime.objects[@(_bitmap)];
        GRect dstRect = bitmap.bounds;
        GRect outerBounds = self.bounds;
        grect_align(&dstRect, &outerBounds, self.alignment, false);
        [bitmap drawInRect:dstRect context:_runtime.graphicsContext];
    }
}

@end
