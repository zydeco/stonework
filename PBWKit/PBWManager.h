//
//  PBWManager.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 31/10/2020.
//  Copyright © 2020 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PBWBundle;

@interface PBWManager : NSObject

@property (nonatomic, readonly) NSURL *documentsURL;
@property (nonatomic, readonly) NSUserDefaults *sharedUserDefaults;

+ (instancetype)defaultManager;
- (NSArray<PBWBundle*>*)availableWatchfaces;

@end

NS_ASSUME_NONNULL_END
