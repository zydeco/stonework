//
//  wall_time.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 13/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../../cpu/cpu.h"
#import "../api.h"
#import "PBWRuntime.h"

uint32_t pbw_api_clock_copy_time_string(pbw_ctx ctx, uint32_t buffer, uint32_t size) {
    if (buffer == 0 || size == 0) return 0;
    NSString *timeString = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
    [timeString getCString:pbw_ctx_get_pointer(ctx, buffer) maxLength:size encoding:NSUTF8StringEncoding];
    return 0;
}

uint32_t pbw_api_clock_is_24h_style(pbw_ctx ctx) {
    NSString *formatStringForHours = [NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]];
    return [formatStringForHours containsString:@"H"] || [formatStringForHours containsString:@"k"];
}

uint32_t pbw_api_clock_to_timestamp(pbw_ctx ctx, uint32_t weekday, uint32_t hour, uint32_t minute) {
    weekday &= 0xff;
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDate *date = [NSDate date];
    NSDateComponents *components = [NSDateComponents new];
    components.weekday = weekday ?: [calendar component:NSCalendarUnitWeekday fromDate:date];
    components.hour = hour;
    components.minute = minute;
    NSDate *nextDate = [calendar nextDateAfterDate:date matchingComponents:components options:NSCalendarMatchNextTime];
    return (int32_t)nextDate.timeIntervalSince1970;
}

uint32_t pbw_api_clock_is_timezone_set(pbw_ctx ctx) {
    return 1;
}

uint32_t pbw_api_clock_get_timezone(pbw_ctx ctx, uint32_t buffer, uint32_t size) {
    if (buffer == 0 || size == 0) return 0;
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    [timeZone.name getCString:pbw_ctx_get_pointer(ctx, buffer) maxLength:size encoding:NSUTF8StringEncoding];
    return 0;
}

