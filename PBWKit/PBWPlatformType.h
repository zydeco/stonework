//
//  PBWPlatformType.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 14/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#ifndef PBWPlatformType_h
#define PBWPlatformType_h

typedef NS_OPTIONS(uint8_t, PBWPlatformType) {
    PBWPlatformTypeNone     = 0,
    PBWPlatformTypeAplite   = 1 << 0,
    PBWPlatformTypeBasalt   = 1 << 1,
    PBWPlatformTypeChalk    = 1 << 2,
    PBWPlatformTypeDiorite  = 1 << 3,
    PBWPlatformTypeEmery    = 1 << 4,
    PBWPlatformTypeUnknown  = 1 << 7
};

NSString * NSStringFromPBWPlatformType(PBWPlatformType platformType);
PBWPlatformType PBWPlatformTypeFromString(NSString *string);

#endif /* PBWPlatformType_h */
