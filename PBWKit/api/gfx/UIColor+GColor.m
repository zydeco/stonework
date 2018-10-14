//
//  UIColor+GColor.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 11/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "UIColor+GColor.h"

static UIColor * GColorTable[256];

@implementation UIColor (GColor)

+ (void)load {
    for (int argb = 0; argb < 256; argb++) {
        CGFloat alphaValue = ((argb >> 6) & 0x03) / 3.0;
        CGFloat redValue = ((argb >> 4) & 0x03) / 3.0;
        CGFloat greenValue = ((argb >> 2) & 0x03) / 3.0;
        CGFloat blueValue = (argb & 0x03) / 3.0;
        GColorTable[argb] = [UIColor colorWithRed:redValue green:greenValue blue:blueValue alpha:alphaValue];
    }
}

+ (instancetype)colorWithGColor:(GColor)gColor {
    return GColorTable[gColor.argb];
}

@end
