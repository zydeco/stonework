//
//  PBWTextLayer.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 01/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWLayer.h"
#import "PBWGraphics.h"

@class PBWFont;

NS_ASSUME_NONNULL_BEGIN

@interface PBWTextLayer : PBWLayer

@property (nonatomic, assign) uint32_t textPtr;
@property (nonatomic, weak) PBWFont *font;
@property (nonatomic, assign) GTextAlignment textAlignment;
@property (nonatomic, assign) GTextOverflowMode overflowMode;
@property (nonatomic, assign) GColor textColor;
@property (nonatomic, assign) GColor backgroundColor;
@property (nonatomic, assign) NSInteger textFlowInset;
@property (nonatomic, readonly) GSize contentSize;

@end

NS_ASSUME_NONNULL_END
