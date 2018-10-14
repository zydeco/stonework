//
//  PBWGraphicsContext.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 11/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWObject.h"
#import <CoreGraphics/CoreGraphics.h>
#import "PBWGraphics.h"

@class PBWWindow, UIColor, UIBezierPath;

NS_ASSUME_NONNULL_BEGIN

@interface PBWGraphicsContext : PBWObject
{
@public
    CGContextRef cgContext;
}

@property (nonatomic, retain) UIColor *fillColor;
@property (nonatomic, retain) UIColor *strokeColor;
@property (nonatomic, retain) UIColor *textColor;
// Color screen only supports Assign and Set
@property (nonatomic, assign) GCompOp compositingMode;
@property (nonatomic, assign) BOOL antialiased;
@property (nonatomic, assign) uint8_t strokeWidth;

- (void)drawWindow:(PBWWindow*)window;
- (UIBezierPath*)pathWithGPath:(uint32_t)ptr;

@end

NS_ASSUME_NONNULL_END
