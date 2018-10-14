//
//  PBWScreenView.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 11/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class PBWRuntime;

@protocol PBWScreenView
- (instancetype)initWithFrame:(CGRect)frame;
- (void)setNeedsDisplay;
- (CGRect)bounds;
@end
