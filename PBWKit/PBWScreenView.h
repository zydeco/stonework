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

@property(nonatomic) CGRect frame;
@property(nonatomic) CGRect bounds;
@property(nonatomic) CGPoint center;
@property(nonatomic) CGAffineTransform transform;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setNeedsDisplay;
- (void)removeFromSuperview;

@end
