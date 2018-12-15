//
//  PBWRuntime+WatchOS.m
//  Stonework WatchKit Extension
//
//  Created by Jesús A. Álvarez on 13/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWRuntime.h"
@import WatchKit;

@implementation PBWRuntime (WatchOS)

#pragma mark - Battery State Service

- (uint32_t)batteryChargeState {
    WKInterfaceDevice *device = [WKInterfaceDevice currentDevice];
    BOOL batteryMonitoringWasEnabled = device.batteryMonitoringEnabled;
    device.batteryMonitoringEnabled = YES;
    uint8_t charge_percent = device.batteryLevel * 100;
    uint8_t is_charging = 0;
    uint8_t is_plugged = 0;
    switch (device.batteryState) {
        case WKInterfaceDeviceBatteryStateCharging:
            is_charging = 1;
        case WKInterfaceDeviceBatteryStateFull:
            is_plugged = 1;
            break;
        default:
            break;
    }
    device.batteryMonitoringEnabled = batteryMonitoringWasEnabled;
    return (is_plugged << 8) | (is_charging << 8) | charge_percent;
}

- (void)setBatteryServiceHandler:(uint32_t)batteryServiceHandler {
    self->_batteryServiceHandler = batteryServiceHandler;
    WKInterfaceDevice *device = [WKInterfaceDevice currentDevice];
    device.batteryMonitoringEnabled = batteryServiceHandler != 0;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    // TODO: set or cancel timer to update battery state
}

@end
