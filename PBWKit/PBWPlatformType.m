//
//  PBWPlatformType.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 14/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBWPlatformType.h"

NSString * NSStringFromPBWPlatformType(PBWPlatformType platformType) {
    if (platformType == PBWPlatformTypeAplite) {
        return @"aplite";
    } else if (platformType == PBWPlatformTypeBasalt) {
        return @"basalt";
    } else if (platformType == PBWPlatformTypeChalk) {
        return @"chalk";
    } else if (platformType == PBWPlatformTypeDiorite) {
        return @"diorite";
    } else if (platformType == PBWPlatformTypeEmery) {
        return @"emery";
    } else {
        return nil;
    }
}

PBWPlatformType PBWPlatformTypeFromString(NSString *platform) {
    if (platform == nil) {
        return PBWPlatformTypeNone;
    } else if ([platform isEqualToString:@"aplite"]) {
        return PBWPlatformTypeAplite;
    } else if ([platform isEqualToString:@"basalt"]) {
        return PBWPlatformTypeBasalt;
    } else if ([platform isEqualToString:@"chalk"]) {
        return PBWPlatformTypeChalk;
    } else if ([platform isEqualToString:@"diorite"]) {
        return PBWPlatformTypeDiorite;
    } else if ([platform isEqualToString:@"emery"]) {
        return PBWPlatformTypeEmery;
    } else {
        return PBWPlatformTypeUnknown;
    }
}
