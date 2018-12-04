//
//  PBWFont.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 01/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWObject.h"
#import "PBWGraphics.h"

@class PBWGraphicsContext;

NS_ASSUME_NONNULL_BEGIN

@interface PBWFont : PBWObject

- (nullable instancetype)initWithRuntime:(PBWRuntime*)rt resourceHandle:(uint32_t)resourceHandle;
- (nullable instancetype)initWithRuntime:(PBWRuntime*)rt fontKey:(NSString*)fontKey;
- (void)drawCharacter:(uint32_t)codepoint inContext:(PBWGraphicsContext*)graphicsContext atPoint:(GPoint)point;
- (void)drawText:(const char *)text inContext:(PBWGraphicsContext*)ctx box:(GRect)box withOverflowMode:(GTextOverflowMode)overflowMode alignment:(GTextAlignment)alignment attributes:(nullable id)attributes;

@end

NS_ASSUME_NONNULL_END
