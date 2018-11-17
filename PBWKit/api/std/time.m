//
//  time.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 11/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWRuntime.h"
#import "../../cpu/cpu.h"
#import "../api.h"
#import <time.h>
#import <sys/time.h>
#import "PBWAddressSpace+Globals.h"

#define TZ_LEN 6

struct __attribute__((__packed__)) pebble_tm {
    int32_t tm_sec;     /*!< Seconds. [0-60] (1 leap second) */
    int32_t tm_min;     /*!< Minutes. [0-59] */
    int32_t tm_hour;    /*!< Hours.  [0-23] */
    int32_t tm_mday;    /*!< Day. [1-31] */
    int32_t tm_mon;     /*!< Month. [0-11] */
    int32_t tm_year;    /*!< Years since 1900 */
    int32_t tm_wday;    /*!< Day of week. [0-6] */
    int32_t tm_yday;    /*!< Days in year.[0-365] */
    int32_t tm_isdst;   /*!< DST. [-1/0/1] */
    int32_t tm_gmtoff;  /*!< Seconds east of UTC */
    char tm_zone[TZ_LEN]; /*!< Timezone abbreviation */
};

uint32_t pbw_api_time(pbw_ctx ctx, uint32_t time_ptr) {
    time_t tv = time(NULL);
    if (time_ptr) {
        pbw_cpu_mem_write(ctx->cpu, time_ptr, PBW_MEM_WORD, (uint32_t)tv);
    }
    return (uint32_t)tv;
}

uint32_t pbw_api_time__deprecated(pbw_ctx ctx, uint32_t time_ptr) {
    // what's the difference?
    return pbw_api_time(ctx, time_ptr);
}

static void tm_host_to_guest(const struct tm *host_tm, struct pebble_tm *guest_tm) {
    OSWriteLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_sec), host_tm->tm_sec);
    OSWriteLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_min), host_tm->tm_min);
    OSWriteLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_hour), host_tm->tm_hour);
    OSWriteLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_mday), host_tm->tm_mday);
    OSWriteLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_mon), host_tm->tm_mon);
    OSWriteLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_year), host_tm->tm_year);
    OSWriteLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_wday), host_tm->tm_wday);
    OSWriteLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_yday), host_tm->tm_yday);
    OSWriteLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_isdst), host_tm->tm_isdst);
    OSWriteLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_gmtoff), host_tm->tm_gmtoff);
    
    strncpy(guest_tm->tm_zone, host_tm->tm_zone, TZ_LEN);
}

static void tm_guest_to_host(const struct pebble_tm *guest_tm, struct tm *host_tm) {
    host_tm->tm_sec = OSReadLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_sec));
    host_tm->tm_min = OSReadLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_min));
    host_tm->tm_hour = OSReadLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_hour));
    host_tm->tm_mday = OSReadLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_mday));
    host_tm->tm_mon = OSReadLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_mon));
    host_tm->tm_year = OSReadLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_year));
    host_tm->tm_wday = OSReadLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_wday));
    host_tm->tm_yday = OSReadLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_yday));
    host_tm->tm_isdst = OSReadLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_isdst));
    host_tm->tm_gmtoff = OSReadLittleInt32(guest_tm, offsetof(struct pebble_tm, tm_gmtoff));
    host_tm->tm_zone = strdup(guest_tm->tm_zone);
}

void PBWRunTick(pbw_ctx ctx, struct tm *host_tm, TimeUnits unitsChanged, uint32_t handler) {
    tm_host_to_guest(host_tm, pbw_ctx_get_pointer(ctx, kPBWGlobalTickTime));
    pbw_cpu_call(ctx->cpu, handler, NULL, 2, kPBWGlobalTickTime, unitsChanged);
}

uint32_t pbw_api_localtime(pbw_ctx ctx, uint32_t timep) {
    struct tm host_tm;
    time_t t = pbw_cpu_mem_read(ctx->cpu, timep, PBW_MEM_READ, PBW_MEM_WORD);
    localtime_r(&t, &host_tm);
    tm_host_to_guest(&host_tm, pbw_ctx_get_pointer(ctx, kPBWGlobalLocaltime));
    return kPBWGlobalLocaltime;
}

uint32_t pbw_api_localtime__deprecated(pbw_ctx ctx, uint32_t timep) {
    return pbw_api_localtime(ctx, timep);
}

uint32_t pbw_api_gmtime(pbw_ctx ctx, uint32_t timep) {
    struct tm host_tm;
    time_t t = pbw_cpu_mem_read(ctx->cpu, timep, PBW_MEM_READ, PBW_MEM_WORD);
    gmtime_r(&t, &host_tm);
    tm_host_to_guest(&host_tm, pbw_ctx_get_pointer(ctx, kPBWGlobalGmtime));
    return kPBWGlobalGmtime;
}

uint32_t pbw_api_mktime(pbw_ctx ctx, uint32_t tb) {
    struct pebble_tm *guest_tm = pbw_ctx_get_pointer(ctx, tb);
    struct tm host_tm;
    tm_guest_to_host(guest_tm, &host_tm);
    time_t time = mktime(&host_tm);
    free(host_tm.tm_zone);
    return (uint32_t)time;
}

uint32_t pbw_api_time_ms(pbw_ctx ctx, uint32_t timep, uint32_t msp) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    if (timep) {
        pbw_cpu_mem_write(ctx->cpu, timep, PBW_MEM_WORD, (uint32_t)tv.tv_sec);
    }
    uint32_t ms = tv.tv_usec / 1000;
    if (msp) {
        pbw_cpu_mem_write(ctx->cpu, msp, PBW_MEM_HALFWORD, ms);
    }
    return ms;
}

uint32_t pbw_api_time_start_of_today(pbw_ctx ctx) {
    time_t t = time(NULL);
    t -= (t % 86400);
    return (uint32_t)t;
}
