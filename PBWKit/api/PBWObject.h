//
//  PBWObject.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 04/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "api.h"

@class PBWRuntime;

NS_ASSUME_NONNULL_BEGIN

@interface PBWObject : NSObject
{
@public
    uint32_t _tag;
    __weak PBWRuntime *_runtime;
}

@property (nonatomic, readonly) uint32_t tag;
@property (nonatomic, readonly, weak) PBWRuntime *runtime;

- (instancetype)initWithRuntime:(PBWRuntime*)rt NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (void)destroy;

@end

NS_ASSUME_NONNULL_END
