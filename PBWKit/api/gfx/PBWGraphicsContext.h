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

extern const uint32_t PBWGraphicsNativePalette[256];
extern CGColorRef PBWGraphicsCGColor[256];

NS_ASSUME_NONNULL_BEGIN

@interface PBWGraphicsContext : PBWObject
{
@public
    CGContextRef cgContext;
}

@property (nonatomic, assign) GColor fillColor;
@property (nonatomic, assign) GColor strokeColor;
@property (nonatomic, assign) GColor textColor;
// Color screen only supports Assign and Set
@property (nonatomic, assign) GCompOp compositingMode;
@property (nonatomic, assign) BOOL antialiased;
@property (nonatomic, assign) uint8_t strokeWidth;

- (void)drawWindow:(PBWWindow*)window;
- (void)setPixel:(GPoint)pixel toColor:(GColor8)color;

@end

NS_ASSUME_NONNULL_END
