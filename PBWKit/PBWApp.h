//
//  PBWApp.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 14/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBWPlatformType.h"

@class PBWBundle;

NS_ASSUME_NONNULL_BEGIN

@interface PBWApp : NSObject

@property (nonatomic, readonly) PBWBundle *bundle;
@property (nonatomic, readonly) PBWPlatformType platform;
@property (nonatomic, readonly) NSDictionary<NSString*, id> *manifest;
@property (nonatomic, readonly) NSData *appBinary;
@property (nonatomic, readonly) NSData *resourcePack;
@property (nonatomic, readonly) NSString *appName;
@property (nonatomic, readonly) NSString *companyName;
@property (nonatomic, readonly) NSString *appVersion;
@property (nonatomic, readonly) NSUUID *UUID;
@property (nonatomic, readonly) uint16_t virtualSize, loadSize;
@property (nonatomic, readonly) uint32_t entryPoint, symbolTableOffset, relocTableOffset, numRelocEntries, appFlags;

- (nullable instancetype)initWithBundle:(PBWBundle*)bundle platform:(PBWPlatformType)platform;
- (nullable NSData*)resourceWithID:(uint32_t)resourceID;

@end

NS_ASSUME_NONNULL_END
