//
//  PBWLayer.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 05/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWLayer.h"
#import "PBWRuntime.h"
#import "../../cpu/cpu.h"
#import "../api.h"
#import "PBWGraphics.h"
#import "../gfx/gcolor_definitions.h"
#import "PBWWindow.h"
#import "PBWGraphicsContext.h"
#import "UIColor+GColor.h"

uint32_t pbw_api_layer_create(pbw_ctx ctx, ARG_GRECT(frame)) {
    return pbw_api_layer_create_with_data(ctx, frame_origin, frame_size, 0);
}

uint32_t pbw_api_layer_create_with_data(pbw_ctx ctx, ARG_GRECT(frame), uint32_t data_size) {
    GRect frame = UNPACK_GRECT(frame);
    PBWLayer *layer = [[PBWLayer alloc] initWithRuntime:ctx->runtime frame:frame dataSize:data_size];
    return layer.tag;
}

uint32_t pbw_api_layer_destroy(pbw_ctx ctx, uint32_t layerTag) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    [layer destroy];
    return 0;
}

uint32_t pbw_api_layer_mark_dirty(pbw_ctx ctx, uint32_t layerTag) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    [layer markDirty];
    return 0;
}

uint32_t pbw_api_layer_set_update_proc(pbw_ctx ctx, uint32_t layerTag, uint32_t callback) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.updateProc = callback;
    return 0;
}

uint32_t pbw_api_layer_set_frame(pbw_ctx ctx, uint32_t layerTag, ARG_GRECT(frame)) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.frame = UNPACK_GRECT(frame);
    return 0;
}

uint32_t pbw_api_layer_get_frame(pbw_ctx ctx, uint32_t retptr, uint32_t layerTag) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    RETURN_GRECT(layer.frame);
    return 0;
}

uint32_t pbw_api_layer_set_bounds(pbw_ctx ctx, uint32_t layerTag, ARG_GRECT(bounds)) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.bounds = UNPACK_GRECT(bounds);
    return 0;
}

uint32_t pbw_api_layer_get_bounds(pbw_ctx ctx, uint32_t retptr, uint32_t layerTag) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    RETURN_GRECT(layer.bounds);
    return 0;
}

uint32_t pbw_api_layer_convert_point_to_screen(pbw_ctx ctx, uint32_t layerTag, uint32_t point) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    GPoint convertedPoint = [layer convertPointToScreen:UNPACK_POINT(point)];
    return PACK_POINT(convertedPoint);
}

uint32_t pbw_api_layer_convert_rect_to_screen(pbw_ctx ctx, uint32_t retptr, uint32_t layerTag, ARG_GRECT(frame)) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    GRect convertedRect = [layer convertRectToScreen:UNPACK_GRECT(frame)];
    RETURN_GRECT(convertedRect);
    return 0;
}

uint32_t pbw_api_layer_get_window(pbw_ctx ctx, uint32_t layerTag) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    return layer.window.tag;
}

uint32_t pbw_api_layer_remove_from_parent(pbw_ctx ctx, uint32_t layerTag) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    [layer removeFromParent];
    return 0;
}

uint32_t pbw_api_layer_remove_child_layers(pbw_ctx ctx, uint32_t layerTag) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    [layer removeChildLayers];
    return 0;
}

uint32_t pbw_api_layer_add_child(pbw_ctx ctx, uint32_t layerTag, uint32_t childTag) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    PBWLayer *child = ctx->runtime.objects[@(childTag)];
    [layer addChild:child];
    return 0;
}

uint32_t pbw_api_layer_insert_below_sibling(pbw_ctx ctx, uint32_t layer_to_insert, uint32_t below_sibling_layer) {
    PBWLayer *layerToInsert = ctx->runtime.objects[@(layer_to_insert)];
    PBWLayer *belowSiblingLayer = ctx->runtime.objects[@(below_sibling_layer)];
    [layerToInsert.parent insertLayer:layerToInsert belowSibling:belowSiblingLayer];
    return 0;
}

uint32_t pbw_api_layer_insert_above_sibling(pbw_ctx ctx, uint32_t layer_to_insert, uint32_t above_sibling_layer) {
    PBWLayer *layerToInsert = ctx->runtime.objects[@(layer_to_insert)];
    PBWLayer *aboveSiblingLayer = ctx->runtime.objects[@(above_sibling_layer)];
    [layerToInsert.parent insertLayer:layerToInsert aboveSibling:aboveSiblingLayer];
    return 0;
}

uint32_t pbw_api_layer_set_hidden(pbw_ctx ctx, uint32_t layerTag, uint32_t hidden) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.hidden = !!hidden;
    return 0;
}

uint32_t pbw_api_layer_get_hidden(pbw_ctx ctx, uint32_t layerTag) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    return layer.hidden;
}

uint32_t pbw_api_layer_set_clips(pbw_ctx ctx, uint32_t layerTag, uint32_t clips) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    layer.clips = !!clips;
    return 0;
}

uint32_t pbw_api_layer_get_clips(pbw_ctx ctx, uint32_t layerTag) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    return layer.clips;
}

uint32_t pbw_api_layer_get_data(pbw_ctx ctx, uint32_t layerTag) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    return layer.dataPtr;
}

uint32_t pbw_api_layer_get_unobstructed_bounds(pbw_ctx ctx, uint32_t retptr, uint32_t layerTag) {
    PBWLayer *layer = ctx->runtime.objects[@(layerTag)];
    RETURN_GRECT([layer unobstructedBounds]);
    return 0;
}


@implementation PBWLayer
{
    NSMutableArray<PBWLayer *> *children;
}

@synthesize children=children;

- (instancetype)initWithRuntime:(PBWRuntime *)rt frame:(GRect)frame dataSize:(size_t)dataSize {
    if (self = [self initWithRuntime:rt]) {
        _frame = frame;
        _bounds = GRect(0, 0, _frame.size.w, _frame.size.h);
        if (dataSize) {
            _dataPtr = pbw_api_malloc(rt.runtimeContext, (uint32_t)dataSize);
        }
        _updateProc = 0;
        _clips = YES;
        _hidden = NO;
        _parent = nil;
        children = [NSMutableArray arrayWithCapacity:0];
    }
    return self;
}

- (void)destroy {
    if (_dataPtr) pbw_api_free(self.runtime.runtimeContext, _dataPtr);
    [super destroy];
}

- (void)setBounds:(GRect)bounds {
    if (!grect_equal(&bounds, &_bounds)) {
        _bounds = bounds;
        [_window markDirty];
    }
}

- (void)addChild:(PBWLayer *)childLayer {
    [childLayer removeFromParent];
    [children addObject:childLayer];
    childLayer->_parent = self;
    childLayer->_window = _window;
    [_window markDirty];
}

- (void)removeFromParent {
    if (_parent) {
        [_parent->children removeObject:self];
        [_parent->_window markDirty];
        _parent = nil;
        _window = nil;
    }
}

- (void)removeChildLayers {
    for (PBWLayer *child in children) {
        child->_parent = nil;
        child->_window = nil;
    }
    [children removeAllObjects];
    [_window markDirty];
}

- (void)insertLayer:(PBWLayer *)childLayer atIndex:(NSUInteger)index {
    [childLayer removeFromParent];
    [children insertObject:childLayer atIndex:index];
    childLayer->_parent = self;
    childLayer->_window = _window;
    [_window markDirty];
}

- (void)insertLayer:(PBWLayer *)childLayer belowSibling:(PBWLayer *)siblingLayer {
    NSUInteger index = [children indexOfObject:siblingLayer];
    if (index != NSNotFound) {
        [self insertLayer:childLayer atIndex:index];
    }
}

- (void)insertLayer:(PBWLayer *)childLayer aboveSibling:(PBWLayer *)siblingLayer {
    NSUInteger index = [children indexOfObject:siblingLayer];
    if (index != NSNotFound) {
        [self insertLayer:childLayer atIndex:index+1];
    }
}

- (GPoint)convertPointToScreen:(GPoint)point {
    for (PBWLayer *layer = self; layer; layer = layer->_parent) {
        point.x += layer->_frame.origin.x;
        point.y += layer->_frame.origin.y;
    }
    return point;
}

- (GRect)convertRectToScreen:(GRect)rect {
    for (PBWLayer *layer = self; layer; layer = layer->_parent) {
        rect.origin.x += layer->_frame.origin.x;
        rect.origin.y += layer->_frame.origin.y;
    }
    return rect;
}

- (GRect)unobstructedBounds {
    return GRectZero;
}

- (void)drawLayerHierarchyInContext:(PBWGraphicsContext*)pbwContext {
    if (_hidden) {
        return;
    }
    
    CGContextRef ctx = pbwContext->cgContext;
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, _frame.origin.x, _frame.origin.y);
    if (_clips) {
        CGContextClipToRect(ctx, CGRectFromGRect(_frame));
    }
    
    // draw children
    for (PBWLayer *child in children) {
        [child drawLayerHierarchyInContext:pbwContext];
    }

    // draw this layer
    if (_updateProc) {
        pbw_cpu_call(_runtime.runtimeContext->cpu, _updateProc, NULL, 2, _tag, pbwContext->_tag);
    } else {
        // layer implementation
        [self drawInContext:ctx];
    }
    CGContextRestoreGState(ctx);
}

- (void)drawInContext:(CGContextRef)ctx {
    if (_window->_rootLayer == self) {
        [[UIColor colorWithGColor:_window->_backgroundColor] setFill];
        UIRectFill(CGRectFromGRect(_bounds));
    }
}

- (void)markDirty {
    [_window markDirty];
}

@end
