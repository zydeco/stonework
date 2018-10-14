//
//  decode.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 20/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#ifndef decode_h
#define decode_h

// instruction decoding

#define ENC_2533(v1,v2,v3,v4) \
uint32_t v1 = (ins & 0x1800) >> 11; \
uint32_t v2 = (ins & 0x07C0) >> 6; \
uint32_t v3 = (ins & 0x38) >> 3; \
uint32_t v4 = ins & 0x07;

#define ENC_533(v2,v3,v4) \
uint32_t v2 = (ins & 0x07C0) >> 6; \
uint32_t v3 = (ins & 0x38) >> 3; \
uint32_t v4 = ins & 0x07;

#define ENC_333(v1,v2,v3) \
uint32_t v1 = (ins & 0x01C0) >> 6; \
uint32_t v2 = (ins & 0x38) >> 3; \
uint32_t v3 = ins & 0x07;

#define ENC_238(v1,v2,v3) \
uint32_t v1 = (ins & 0x1800) >> 11; \
uint32_t v2 = (ins & 0x0700) >> 8; \
uint32_t v3 = ins & 0xff;

#define ENC_433(v1,v2,v3) \
uint32_t v1 = (ins & 0x03C0) >> 6; \
uint32_t v2 = (ins & 0x38) >> 3; \
uint32_t v3 = ins & 0x07;

#define ENC_33(v2,v3) \
uint32_t v2 = (ins & 0x38) >> 3; \
uint32_t v3 = ins & 0x07;

#define ENC_OpHsHd(v1,v2,v3) \
uint32_t v1 = (ins & 0x0300) >> 8; \
uint32_t v2 = (ins & 0x78) >> 3; \
uint32_t v3 = ((ins & 0x80) >> 4) | (ins & 0x07);

#define ENC_HsHd(v1,v2) \
uint32_t v1 = (ins & 0x78) >> 3; \
uint32_t v2 = ((ins & 0x80) >> 4) | (ins & 0x07);

#define ENC_38(v1,v2) \
uint32_t v1 = (ins & 0x0700) >> 8; \
uint32_t v2 = ins & 0xff;

#define ENC_48(v1,v2) \
uint32_t v1 = (ins & 0x0f00) >> 8; \
uint32_t v2 = ins & 0xff;

#endif /* decode_h */
