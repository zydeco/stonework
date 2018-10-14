//
//  UIColor+GColor.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 11/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBWGraphics.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (GColor)

+ (instancetype)colorWithGColor:(GColor)gColor;

@end

NS_ASSUME_NONNULL_END
