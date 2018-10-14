//
//  NSString+PBWRuntime.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 17/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "api.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSString (PBWRuntime)

+ (instancetype)stringWithPBWContext:(pbw_ctx)ctx formatArgument:(int)fmtArg;

@end

NS_ASSUME_NONNULL_END
