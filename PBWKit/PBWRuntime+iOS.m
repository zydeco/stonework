//
//  PBWRuntime+iOS.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 13/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWRuntime.h"
@import UIKit;

@implementation PBWRuntime (iOS)

#pragma mark - Battery State Service

- (uint32_t)batteryChargeState {
    UIDevice *device = [UIDevice currentDevice];
    BOOL batteryMonitoringWasEnabled = device.batteryMonitoringEnabled;
    device.batteryMonitoringEnabled = YES;
    uint8_t charge_percent = device.batteryLevel * 100;
    uint8_t is_charging = 0;
    uint8_t is_plugged = 0;
    switch (device.batteryState) {
        case UIDeviceBatteryStateCharging:
            is_charging = 1;
        case UIDeviceBatteryStateFull:
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
    UIDevice *device = [UIDevice currentDevice];
    device.batteryMonitoringEnabled = batteryServiceHandler != 0;
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    if (device.batteryMonitoringEnabled) {
        [nc addObserver:self selector:@selector(batteryLevelOrStateDidChange:) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
        [nc addObserver:self selector:@selector(batteryLevelOrStateDidChange:) name:UIDeviceBatteryStateDidChangeNotification object:nil];
    } else {
        [nc removeObserver:self name:UIDeviceBatteryLevelDidChangeNotification object:nil];
        [nc removeObserver:self name:UIDeviceBatteryStateDidChangeNotification object:nil];
    }
}

@end
