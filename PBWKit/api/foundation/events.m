//
//  events.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 10/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>
#import "../../cpu/cpu.h"
#import "../api.h"
#import "PBWRuntime.h"

#pragma mark - Battery Service
uint32_t pbw_api_battery_state_service_subscribe(pbw_ctx ctx, uint32_t handler) {
    ctx->runtime.batteryServiceHandler = handler;
    return 0;
}

uint32_t pbw_api_battery_state_service_unsubscribe(pbw_ctx ctx) {
    ctx->runtime.batteryServiceHandler = 0;
    return 0;
}

uint32_t pbw_api_battery_state_service_peek(pbw_ctx ctx) {
    return ctx->runtime.batteryChargeState;
}


#pragma mark - Connection Service

uint32_t pbw_api_connection_service_peek_pebble_app_connection(pbw_ctx ctx) {
#if TARGET_OS_WATCH
    return [WCSession defaultSession].reachable;
#else
    return 1;
#endif
}

uint32_t pbw_api_connection_service_peek_pebblekit_connection(pbw_ctx ctx) {
#if TARGET_OS_WATCH
    return [WCSession defaultSession].reachable;
#else
    return 1;
#endif
}

uint32_t pbw_api_connection_service_subscribe(pbw_ctx ctx, uint32_t app_connection_handler, uint32_t pebblekit_connection_handler) {
    ctx->runtime.connAppHandler = app_connection_handler;
    ctx->runtime.connPebbleKitHandler = pebblekit_connection_handler;
    return 0;
}

uint32_t pbw_api_connection_service_unsubscribe(pbw_ctx ctx) {
    ctx->runtime.connAppHandler = 0;
    ctx->runtime.connPebbleKitHandler = 0;
    return 0;
}

uint32_t pbw_api_bluetooth_connection_service_peek(pbw_ctx ctx) {
#if TARGET_OS_WATCH
    return [WCSession defaultSession].reachable;
#else
    return 1;
#endif
}

uint32_t pbw_api_bluetooth_connection_service_subscribe(pbw_ctx ctx, uint32_t handler) {
    ctx->runtime.connBluetoothHandler = handler;
    return 0;
}

uint32_t pbw_api_bluetooth_connection_service_unsubscribe(pbw_ctx ctx) {
    ctx->runtime.connBluetoothHandler = 0;
    return 0;
}

#pragma mark - Tick Timer Service

uint32_t pbw_api_tick_timer_service_subscribe(pbw_ctx ctx, uint32_t units, uint32_t handler) {
    [ctx->runtime startTickTimerWithUnits:units handler:handler];
    return 0;
}

uint32_t pbw_api_tick_timer_service_unsubscribe(pbw_ctx ctx) {
    [ctx->runtime startTickTimerWithUnits:0 handler:0];
    return 0;
}
