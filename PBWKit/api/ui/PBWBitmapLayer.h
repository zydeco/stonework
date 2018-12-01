//
//  PBWBitmapLayer.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 18/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWLayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface PBWBitmapLayer : PBWLayer

@property (nonatomic, assign) GCompOp compositingMode;
@property (nonatomic, assign) GColor backgroundColor;
@property (nonatomic, assign) uint32_t bitmap;
@property (nonatomic, assign) GAlign alignment;

@end

NS_ASSUME_NONNULL_END
