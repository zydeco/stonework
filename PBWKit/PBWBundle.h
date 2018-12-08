//
//  PBWBundle.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 14/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBWPlatformType.h"

NS_ASSUME_NONNULL_BEGIN

@interface PBWBundle : NSObject

@property (nonatomic, readonly) NSURL *bundleURL;

// App Info
@property (nonatomic, readonly) NSDictionary<NSString *,id> *infoDictionary;
@property (nonatomic, readonly) PBWPlatformType targetPlatforms;
@property (nonatomic, readonly) NSUUID *UUID;
@property (nonatomic, readonly) NSString *shortName;
@property (nonatomic, readonly) NSString *longName;
@property (nonatomic, readonly) NSString *versionLabel;
@property (nonatomic, readonly) NSString *companyName;
@property (nonatomic, readonly) BOOL isWatchFace;
@property (nonatomic, readonly, getter=isConfigurable) BOOL configurable;

+ (nullable instancetype)bundleWithURL:(NSURL*)url;
+ (NSArray<PBWBundle*>*)bundlesAtURL:(NSURL*)url;
- (nullable instancetype)initWithURL:(NSURL*)url;
- (nullable NSData*)dataAtPath:(NSString*)path;

@end

NS_ASSUME_NONNULL_END
