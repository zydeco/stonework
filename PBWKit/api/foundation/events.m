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
    [ctx->runtime startTickTimerWithUnits:units handler:handler];
    return 0;
}

uint32_t pbw_api_tick_timer_service_unsubscribe(pbw_ctx ctx) {
    [ctx->runtime startTickTimerWithUnits:0 handler:0];
    return 0;
}
