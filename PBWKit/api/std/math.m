//
//  math.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 2024-05-06.
//  Copyright © 2024 namedfork. All rights reserved.
//


#import "PBWRuntime.h"
#import "../../cpu/cpu.h"
#import "../api.h"

uint32_t pbw_api_rand(pbw_ctx ctx) {
    return rand();
}

uint32_t pbw_api_srand(pbw_ctx ctx, uint32_t seed) {
    srand(seed);
    return 0;
}
