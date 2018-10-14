//
//  alu.c
//  Stonework
//
//  Created by Jesús A. Álvarez on 17/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#include "cpu_priv.h"
#include "alu.h"
#include "ops.h"

uint32_t pbw_cpu_alu_add(pbw_cpu cpu, uint32_t x, uint32_t y, uint32_t carry_in, uint32_t setflags) {
    uint64_t unsigned_sum = (uint64_t)x + (uint64_t)y + (uint64_t)carry_in;
    int64_t signed_sum = (int64_t)x + (int64_t)y + (uint64_t)carry_in;
    uint32_t result = unsigned_sum & 0xFFFFFFFF;
    if (setflags) {
        SetAPSR_NZCV(result, result == unsigned_sum, (int64_t)((int32_t)result) != signed_sum);
    }
    return result;
}

