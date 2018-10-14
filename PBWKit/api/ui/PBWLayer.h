//
//  PBWLayer.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 05/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWObject.h"
#import "PBWGraphics.h"
#import <CoreGraphics/CoreGraphics.h>

@class PBWWindow, PBWGraphicsContext;

NS_ASSUME_NONNULL_BEGIN

@interface PBWLayer : PBWObject

@property (nonatomic, assign) GRect frame;
@property (nonatomic, assign) GRect bounds;
@property (nonatomic, assign) BOOL clips;
@property (nonatomic, assign) BOOL hidden;
@property (nonatomic, assign) uint32_t updateProc;
@property (nonatomic, assign) uint32_t dataPtr;
@property (nonatomic, weak) PBWWindow *window;
@property (nonatomic, readonly, weak) PBWLayer *parent;
@property (nonatomic, readonly) NSArray<PBWLayer*> *children;

- (instancetype)initWithRuntime:(PBWRuntime *)rt frame:(GRect)frame dataSize:(size_t)dataSize;

- (GPoint)convertPointToScreen:(GPoint)point;
- (GRect)convertRectToScreen:(GRect)rect;
- (void)removeFromParent;
- (void)removeChildLayers;
- (void)addChild:(PBWLayer*)childLayer;
- (void)insertLayer:(PBWLayer*)childLayer aboveSibling:(PBWLayer*)siblingLayer;
- (void)insertLayer:(PBWLayer*)childLayer belowSibling:(PBWLayer*)siblingLayer;
- (GRect)unobstructedBounds;
- (void)drawLayerHierarchyInContext:(PBWGraphicsContext*)ctx;
- (void)drawInContext:(CGContextRef)ctx;

@end

NS_ASSUME_NONNULL_END
