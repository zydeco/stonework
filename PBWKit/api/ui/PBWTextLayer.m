//
//  PBWTextLayer.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 01/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWTextLayer.h"
#import "PBWRuntime.h"
#import "PBWFont.h"
#import "PBWGraphicsContext.h"

uint32_t pbw_api_text_layer_create(pbw_ctx ctx, ARG_GRECT(frame)) {
    PBWTextLayer *layer = [[PBWTextLayer alloc] initWithRuntime:ctx->runtime frame:UNPACK_GRECT(frame) dataSize:0];
    return layer.tag;
}

uint32_t pbw_api_text_layer_destroy(pbw_ctx ctx, uint32_t layerTag) {
    PBWTextLayer *layer = ctx->runtime.objects[@(layerTag)];
    [layer destroy];
    return 0;
}

uint32_t pbw_api_text_layer_get_layer(pbw_ctx ctx, uint32_t layerTag) {
    return layerTag;
}

uint32_t pbw_api_text_layer_set_text(pbw_ctx ctx, uint32_t layerTag, uint32_t textPtr) {
    PBWTextLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.textPtr = textPtr;
    return 0;
}

uint32_t pbw_api_text_layer_get_text(pbw_ctx ctx, uint32_t layerTag) {
    PBWTextLayer *layer = ctx->runtime.objects[@(layerTag)];
    return layer.textPtr;
}

uint32_t pbw_api_text_layer_set_background_color(pbw_ctx ctx, uint32_t layerTag, uint32_t color) {
    PBWTextLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.backgroundColor = GColor(color & 0xff);
    return 0;
}

uint32_t pbw_api_text_layer_set_background_color_2bit(pbw_ctx ctx, uint32_t layerTag, uint32_t color) {
    PBWTextLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.backgroundColor = GColorFrom2Bit(color & 0xff);
    return 0;
}

uint32_t pbw_api_text_layer_set_text_color(pbw_ctx ctx, uint32_t layerTag, uint32_t color) {
    PBWTextLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.textColor = GColor(color & 0xff);
    return 0;
}

uint32_t pbw_api_text_layer_set_text_color_2bit(pbw_ctx ctx, uint32_t layerTag, uint32_t color) {
    PBWTextLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.textColor = GColorFrom2Bit(color & 0xff);
    return 0;
}

uint32_t pbw_api_text_layer_set_overflow_mode(pbw_ctx ctx, uint32_t layerTag, uint32_t line_mode) {
    PBWTextLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.overflowMode = line_mode & 0xff;
    return 0;
}

uint32_t pbw_api_text_layer_set_font(pbw_ctx ctx, uint32_t layerTag, uint32_t fontTag) {
    PBWTextLayer *layer = ctx->runtime.objects[@(layerTag)];
    PBWFont *font = ctx->runtime.objects[@(fontTag)];
    layer.font = font;
    return 0;
}

uint32_t pbw_api_text_layer_set_text_alignment(pbw_ctx ctx, uint32_t layerTag, uint32_t text_alignment) {
    PBWTextLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.textAlignment = text_alignment & 0xff;
    return 0;
}

uint32_t pbw_api_text_layer_enable_screen_text_flow_and_paging(pbw_ctx ctx, uint32_t layerTag, uint32_t inset) {
    PBWTextLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.textFlowInset = inset & 0xff;
    return 0;
}

uint32_t pbw_api_text_layer_restore_default_text_flow_and_paging(pbw_ctx ctx, uint32_t layerTag) {
    PBWTextLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.textFlowInset = NSNotFound;
    return 0;
}

uint32_t pbw_api_text_layer_get_content_size(pbw_ctx ctx, uint32_t layerTag) {
    PBWTextLayer *layer = ctx->runtime.objects[@(layerTag)];
    return PACK_SIZE(layer.contentSize);
}

uint32_t pbw_api_text_layer_set_size(pbw_ctx ctx, uint32_t layerTag, uint32_t size) {
    PBWTextLayer *layer = ctx->runtime.objects[@(layerTag)];
    GRect frame = layer.frame;
    frame.size = UNPACK_SIZE(size);
    layer.frame = frame;
    return 0;
}

@implementation PBWTextLayer

- (instancetype)initWithRuntime:(PBWRuntime *)rt frame:(GRect)frame dataSize:(size_t)dataSize {
    if (self = [super initWithRuntime:rt frame:frame dataSize:dataSize]) {
        self.font = [rt systemFontWithKey:@"FONT_KEY_GOTHIC_14_BOLD"];
        self.textPtr = 0;
        self.textAlignment = GTextAlignmentLeft;
        self.textColor = GColorBlack;
        self.backgroundColor = GColorWhite;
        self.clips = YES;
        self.hidden = NO;
        self.textFlowInset = NSNotFound;
        [self markDirty];
    }
    return self;
}

- (void)drawInContext:(CGContextRef)cg {
    CGContextSetFillColorWithColor(cg, PBWGraphicsCGColor[_backgroundColor.argb]);
    CGContextFillRect(cg, CGRectFromGRect(self.bounds));
    if (_textPtr) {
        const char *text = pbw_ctx_get_pointer(_runtime.runtimeContext, _textPtr);
        GRect textBox = [self convertRectToScreen:self.bounds];
        textBox.size.h *= 2;
        [_font drawText:text inContext:_runtime.graphicsContext box:textBox withOverflowMode:_overflowMode alignment:_textAlignment attributes:nil];
    }
}

- (GSize)contentSize {
    return GSize(0, 0);
}

@end
