//
//  events.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 10/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../../cpu/cpu.h"
#import "../api.h"
#import "PBWRuntime.h"

#pragma mark - Tick Timer Service

uint32_t pbw_api_tick_timer_service_subscribe(pbw_ctx ctx, uint32_t units, uint32_t handler) {
    pbw_api_tick_timer_service_unsubscribe(ctx);
    NSTimeInterval thisTick = floor([NSDate timeIntervalSinceReferenceDate]);
    NSDate *nextFireDate = [NSDate dateWithTimeIntervalSinceReferenceDate:thisTick + 1.0];
    NSDictionary *userInfo = @{@"units": @(units), @"handler": @(handler)};
    NSTimer *tickTimer = [[NSTimer alloc] initWithFireDate:nextFireDate interval:1.0 target:ctx->runtime selector:@selector(tick:) userInfo:userInfo repeats:YES];
    ctx->runtime.tickTimer = tickTimer;
    ctx->runtime.lastTick = thisTick;
    return 0;
}

uint32_t pbw_api_tick_timer_service_unsubscribe(pbw_ctx ctx) {
    if (ctx->runtime.tickTimer) {
        [ctx->runtime.tickTimer invalidate];
        ctx->runtime.tickTimer = nil;
    }
    return 0;
}
