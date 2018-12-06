//
//  PBWWindow.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 04/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWRuntime.h"
#import "../../cpu/cpu.h"
#import "../api.h"
#import "PBWWindow.h"
#import "PBWLayer.h"
#import "../gfx/gcolor_definitions.h"

uint32_t pbw_api_window_create(pbw_ctx ctx) {
    PBWWindow *window = [[PBWWindow alloc] initWithRuntime:ctx->runtime];
    return window.tag;
}

uint32_t pbw_api_window_destroy(pbw_ctx ctx, uint32_t wtag) {
    PBWWindow *window = ctx->runtime.objects[@(wtag)];
    [window destroy];
    return 0;
}

uint32_t pbw_api_window_set_click_config_provider(pbw_ctx ctx, uint32_t wtag, uint32_t click_config_provider) {
    pbw_api_window_set_click_config_provider_with_context(ctx, wtag, click_config_provider, wtag);
    return 0;
}

uint32_t pbw_api_window_set_click_config_provider_with_context(pbw_ctx ctx, uint32_t wtag, uint32_t click_config_provider, uint32_t context) {
    PBWWindow *window = ctx->runtime.objects[@(wtag)];
    window.clickConfigProvider = click_config_provider;
    window.clickConfigProviderContext = context;
    return 0;
}

uint32_t pbw_api_window_get_click_config_provider(pbw_ctx ctx, uint32_t wtag) {
    PBWWindow *window = ctx->runtime.objects[@(wtag)];
    return window.clickConfigProvider;
}

uint32_t pbw_api_window_get_click_config_context(pbw_ctx ctx, uint32_t wtag) {
    PBWWindow *window = ctx->runtime.objects[@(wtag)];
    return window.clickConfigProviderContext;
}

uint32_t pbw_api_window_set_window_handlers(pbw_ctx ctx, uint32_t wtag) {
    // WindowHandlers in r1,r2,r3 and stack
    PBWWindow *window = ctx->runtime.objects[@(wtag)];
    window.loadHandler = pbw_cpu_reg_get(ctx->cpu, 1);
    window.appearHandler = pbw_cpu_reg_get(ctx->cpu, 2);
    window.disapperHandler = pbw_cpu_reg_get(ctx->cpu, 3);
    window.unloadHandler = pbw_cpu_stack_peek(ctx->cpu, 0);
    return 0;
}

uint32_t pbw_api_window_get_root_layer(pbw_ctx ctx, uint32_t wtag) {
    PBWWindow *window = ctx->runtime.objects[@(wtag)];
    return window.rootLayer.tag;
}

uint32_t pbw_api_window_set_background_color(pbw_ctx ctx, uint32_t wtag, uint32_t color) {
    PBWWindow *window = ctx->runtime.objects[@(wtag)];
    color &= 0xff;
    window.backgroundColor = (GColor8){.argb = color};
    return 0;
}

uint32_t pbw_api_window_set_background_color_2bit(pbw_ctx ctx, uint32_t wtag, uint32_t color) {
    PBWWindow *window = ctx->runtime.objects[@(wtag)];
    uint8_t colorValue = color & 0xff;
    window.backgroundColor = GColorFrom2Bit(colorValue);
    return 0;
}

uint32_t pbw_api_window_stack_push(pbw_ctx ctx, uint32_t wtag, uint32_t animated) {
    PBWWindow *window = ctx->runtime.objects[@(wtag)];
    [ctx->runtime.windowStack addObject:window];
    [ctx->runtime.screenView setNeedsDisplay];
    return 0;
}

@implementation PBWWindow

- (instancetype)initWithRuntime:(PBWRuntime *)rt {
    if (self = [super initWithRuntime:rt]) {
        CGSize screenSize = rt.screenSize;
        _rootLayer = [[PBWLayer alloc] initWithRuntime:rt frame:GRect(0, 0, screenSize.width, screenSize.height) dataSize:0];
        _rootLayer.window = self;
        _backgroundColor = GColorWhite;
        _loaded = NO;
        _loadHandler = 0;
        _appearHandler = 0;
        _disapperHandler = 0;
        _unloadHandler = 0;
        _clickConfigProvider = 0;
        _clickConfigProviderContext = 0;
        dirty = YES;
    }
    return self;
}

- (void)destroy {
    [_rootLayer destroy];
    [super destroy];
}

- (void)markDirty {
    dirty = YES;
    if (_runtime.windowStack.lastObject == self) {
        [_runtime.screenView setNeedsDisplay];
    }
}

@end


