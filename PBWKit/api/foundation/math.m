//
//  math.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 13/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWRuntime.h"
#import "../../cpu/cpu.h"
#import "../api.h"
#import <math.h>

uint32_t pbw_api_sin_lookup(pbw_ctx ctx, uint32_t r_angle) {
    int32_t angle = r_angle;
    int32_t result = TRIG_MAX_RATIO * sin(TRIG_TO_RADIANS(angle));
    return result;
}

uint32_t pbw_api_cos_lookup(pbw_ctx ctx, uint32_t r_angle) {
    int32_t angle = r_angle;
    int32_t result = TRIG_MAX_RATIO * cos(TRIG_TO_RADIANS(angle));
    return result;
}

uint32_t pbw_api_atan2_lookup(pbw_ctx ctx, uint32_t ry, uint32_t rx) {
    int16_t y = (int16_t)((int32_t)ry);
    int16_t x = (int16_t)((int32_t)rx);
    int32_t result = TRIG_MAX_RATIO * (atan2(TRIG_TO_RADIANS(y), TRIG_TO_RADIANS(x)) / (2 * M_PI));
    return result;
}
