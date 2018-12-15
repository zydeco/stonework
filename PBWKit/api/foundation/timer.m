//
//  timer.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 15/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../../cpu/cpu.h"
#import "../api.h"
#import "PBWRuntime.h"
#import "PBWObject.h"

@interface PBWAppTimer : PBWObject
@property (nonatomic, assign) uint32_t callback, data;
@property (nonatomic, readonly) BOOL hasFired;
- (void)fire;
- (void)cancel;
@end

uint32_t pbw_api_psleep(pbw_ctx ctx, uint32_t millis) {
    int32_t timeout_ms = millis;
    if (timeout_ms > 0) {
        NSTimeInterval timeout = timeout_ms / 1000.0;
        [NSThread sleepForTimeInterval:timeout];
    }
    return 0;
}

uint32_t pbw_api_app_timer_register(pbw_ctx ctx, uint32_t timeout_ms, uint32_t callback, uint32_t callback_data) {
    NSTimeInterval timeout = timeout_ms / 1000.0;
    if (callback) {
        PBWAppTimer *timer = [[PBWAppTimer alloc] initWithRuntime:ctx->runtime];
        timer.callback = callback;
        timer.data = callback_data;
        [timer performSelector:@selector(fire) withObject:nil afterDelay:timeout];
        return timer.tag;
    } else {
        return 0;
    }
}

uint32_t pbw_api_app_timer_reschedule(pbw_ctx ctx, uint32_t timer_tag, uint32_t new_timeout_ms) {
    PBWAppTimer *timer = ctx->runtime.objects[@(timer_tag)];
    if (timer && [timer isKindOfClass:[PBWAppTimer class]] && !timer.hasFired) {
        NSTimeInterval timeout = new_timeout_ms / 1000.0;
        [timer cancel];
        [timer performSelector:@selector(fire) withObject:nil afterDelay:timeout];
        return 1;
    } else {
        return 0;
    }
}

uint32_t pbw_api_app_timer_cancel(pbw_ctx ctx, uint32_t timer_tag) {
    PBWAppTimer *timer = ctx->runtime.objects[@(timer_tag)];
    if (timer && [timer isKindOfClass:[PBWAppTimer class]]) {
        [timer cancel];
        [timer destroy];
    }
    return 0;
}

@implementation PBWAppTimer

- (void)fire {
    _hasFired = YES;
    pbw_cpu_call(_runtime.runtimeContext->cpu, _callback, NULL, 1, _data);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self destroy];
    });
}

- (void)cancel {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fire) object:nil];
}

@end
