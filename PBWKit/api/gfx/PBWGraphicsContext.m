//
//  PBWGraphicsContext.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 11/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWGraphicsContext.h"
#import "PBWWindow.h"
#import "PBWLayer.h"
#import "PBWRuntime.h"
#import <UIKit/UIKit.h>
#import "UIColor+GColor.h"
#import "weemalloc.h"

#define ReadRAMPointer(p) (p ? p - ctx->ramBase : 0)
#define MakeRAMPointer(p) (p ? p + ctx->ramBase : 0)

#pragma mark - Drawing Paths

uint32_t pbw_api_gpath_create(pbw_ctx ctx, uint32_t init) {
    uint32_t numPoints = pbw_cpu_read_word(ctx->cpu, init);
    uint32_t totalSize = 16 + (numPoints * 4);
    uint32_t gpathPtr = MakeRAMPointer(weemalloc(ctx->heapPtr, totalSize));
    if (gpathPtr == 0) {
        return 0;
    }
    // initialize GPath structure
    void *gpath = pbw_ctx_get_pointer(ctx, gpathPtr);
    OSWriteLittleInt32(gpath, 0, numPoints);
    OSWriteLittleInt32(gpath, 4, gpathPtr + 16);
    OSWriteLittleInt32(gpath, 8, 0); // rotation
    OSWriteLittleInt32(gpath, 12, 0); // offset
    // copy points
    uint32_t pointsPtr = pbw_cpu_read_word(ctx->cpu, init+4);
    void *pointsSrc = pbw_ctx_get_pointer(ctx, pointsPtr);
    memcpy(gpath + 16, pointsSrc, numPoints * 4);
    
    return gpathPtr;
}

uint32_t pbw_api_gpath_destroy(pbw_ctx ctx, uint32_t path) {
    pbw_api_free(ctx, path);
    return 0;
}

uint32_t pbw_api_gpath_draw_filled(pbw_ctx ctx, uint32_t gctx, uint32_t pathPtr) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    CGContextRef cg = graphicsContext->cgContext;
    CGContextSetFillColorWithColor(cg, graphicsContext.fillColor.CGColor);
    CGContextSetStrokeColorWithColor(cg, graphicsContext.fillColor.CGColor);
    CGContextSetLineWidth(cg, 1.0);
    UIBezierPath *path = [graphicsContext pathWithGPath:pathPtr];
    [path applyTransform:CGAffineTransformMakeTranslation(0.5, 0.5)];
    [path closePath];
    CGContextBeginPath(cg);
    CGContextAddPath(cg, path.CGPath);
    CGContextFillPath(cg);
    return 0;
}

uint32_t pbw_api_gpath_draw_filled_legacy(pbw_ctx ctx, uint32_t gctx, uint32_t pathPtr) {
    pbw_api_gpath_draw_filled(ctx, gctx, pathPtr);
    return 0;
}

uint32_t pbw_api_gpath_draw_outline(pbw_ctx ctx, uint32_t gctx, uint32_t pathPtr) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    CGContextRef cg = graphicsContext->cgContext;
    CGContextSetStrokeColorWithColor(cg, graphicsContext.strokeColor.CGColor);
    CGContextSetLineWidth(cg, graphicsContext.strokeWidth);
    UIBezierPath *path = [graphicsContext pathWithGPath:pathPtr];
    [path applyTransform:CGAffineTransformMakeTranslation(0.5, 0.5)];
    [path closePath];
    CGContextBeginPath(cg);
    CGContextAddPath(cg, path.CGPath);
    CGContextStrokePath(cg);
    return 0;
}

uint32_t pbw_api_gpath_rotate_to(pbw_ctx ctx, uint32_t gpathPtr, int32_t angle) {
    void *gpath = pbw_ctx_get_pointer(ctx, gpathPtr);
    OSWriteLittleInt32(gpath, 8, angle);
    return 0;
}

uint32_t pbw_api_gpath_move_to(pbw_ctx ctx, uint32_t gpathPtr, uint32_t pointArg) {
    void *gpath = pbw_ctx_get_pointer(ctx, gpathPtr);
    GPoint point = UNPACK_POINT(pointArg);
    OSWriteLittleInt32(gpath, 12, PACK_POINT(point));
    return 0;
}

uint32_t pbw_api_gpath_draw_outline_open(pbw_ctx ctx, uint32_t gctx, uint32_t pathPtr) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    CGContextRef cg = graphicsContext->cgContext;
    CGContextSetStrokeColorWithColor(cg, graphicsContext.strokeColor.CGColor);
    CGContextSetLineWidth(cg, graphicsContext.strokeWidth);
    UIBezierPath *path = [graphicsContext pathWithGPath:pathPtr];
    [path applyTransform:CGAffineTransformMakeTranslation(0.5, 0.5)];
    CGContextBeginPath(cg);
    CGContextAddPath(cg, path.CGPath);
    CGContextStrokePath(cg);
    return 0;
}


#pragma mark - Drawing Primitives

uint32_t pbw_api_graphics_draw_pixel(pbw_ctx ctx, uint32_t gctx, uint32_t point_arg) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    CGContextRef cg = graphicsContext->cgContext;
    GPoint point = UNPACK_POINT(point_arg);
    CGContextSetFillColorWithColor(cg, graphicsContext.fillColor.CGColor);
    CGContextFillRect(cg, CGRectMake(point.x, point.y, 1, 1));
    return 0;
}

uint32_t pbw_api_graphics_draw_line(pbw_ctx ctx, uint32_t gctx, uint32_t p0, uint32_t p1) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    CGContextRef cg = graphicsContext->cgContext;
    GPoint point0 = UNPACK_POINT(p0);
    GPoint point1 = UNPACK_POINT(p1);
    CGContextBeginPath(cg);
    CGContextMoveToPoint(cg, point0.x + 0.5, point0.y + 0.5);
    CGContextAddLineToPoint(cg, point1.x + 0.5, point1.y + 0.5);
    CGContextSetStrokeColorWithColor(cg, graphicsContext.strokeColor.CGColor);
    CGContextSetLineWidth(cg, graphicsContext.strokeWidth);
    CGContextDrawPath(cg, kCGPathStroke);
    return 0;
}

uint32_t pbw_api_graphics_draw_rect(pbw_ctx ctx, uint32_t gctx, ARG_GRECT(rect)) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    CGContextRef cg = graphicsContext->cgContext;
    CGContextSetStrokeColorWithColor(cg, graphicsContext.strokeColor.CGColor);
    CGContextSetLineWidth(cg, 1.0);
    CGRect rect = CGRectFromGRect(UNPACK_GRECT(rect));
    CGContextStrokeRect(cg, CGRectOffset(rect, 0.5, 0.5));
    return 0;
}

uint32_t pbw_api_graphics_fill_rect(pbw_ctx ctx, uint32_t gctx, ARG_GRECT(rect), uint32_t corner_radius) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    CGContextRef cg = graphicsContext->cgContext;
    CGRect rect = CGRectInset(CGRectFromGRect(UNPACK_GRECT(rect)), 0.5, 0.5);
    corner_radius &= 0xffff;
    UIRectCorner corners = pbw_cpu_stack_peek(ctx->cpu, 0) & 0xf; // coincidentally, same format
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:corners cornerRadii:CGSizeMake(corner_radius, corner_radius)];
    CGContextSetFillColorWithColor(cg, graphicsContext.fillColor.CGColor);
    CGContextBeginPath(cg);
    CGContextAddPath(cg, path.CGPath);
    CGContextFillPath(cg);
    return 0;
}

uint32_t pbw_api_graphics_draw_circle(pbw_ctx ctx, uint32_t gctx, uint32_t center, uint32_t radius) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    CGContextRef cg = graphicsContext->cgContext;
    GPoint centerPoint = UNPACK_POINT(center);
    CGRect rect = CGRectMake(centerPoint.x - 0.5 - radius, centerPoint.y - 0.5 - radius, 2*radius, 2*radius);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:rect];
    CGContextSetStrokeColorWithColor(cg, graphicsContext.strokeColor.CGColor);
    CGContextSetLineWidth(cg, graphicsContext.strokeWidth);
    CGContextBeginPath(cg);
    CGContextAddPath(cg, path.CGPath);
    CGContextStrokePath(cg);
    return 0;
}

uint32_t pbw_api_graphics_fill_circle(pbw_ctx ctx, uint32_t gctx, uint32_t center, uint32_t radius) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    CGContextRef cg = graphicsContext->cgContext;
    GPoint centerPoint = UNPACK_POINT(center);
    CGRect rect = CGRectMake(centerPoint.x - 0.5 - radius, centerPoint.y - 0.5 - radius, 2*radius, 2*radius);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:rect];
    CGContextSetFillColorWithColor(cg, graphicsContext.fillColor.CGColor);
    CGContextBeginPath(cg);
    CGContextAddPath(cg, path.CGPath);
    CGContextFillPath(cg);
    return 0;
}

uint32_t pbw_api_graphics_draw_round_rect(pbw_ctx ctx, uint32_t gctx, ARG_GRECT(rect), uint32_t corner_radius) {
    return 0;
}

uint32_t pbw_api_graphics_draw_bitmap_in_rect(pbw_ctx ctx, uint32_t gctx, uint32_t bitmap, ARG_GRECT(rect)) {
    return 0;
}

uint32_t pbw_api_graphics_draw_arc(pbw_ctx ctx, uint32_t gctx, ARG_GRECT(rect), uint32_t scale_mode) {
    // stack: int32_t angle_start, int32_t angle_end
    return 0;
}

uint32_t pbw_api_graphics_fill_radial(pbw_ctx ctx, uint32_t gctx, ARG_GRECT(rect), uint32_t scale_mode) {
    // stack: uint16_t inset_thickness, int32_t angle_start, int32_t angle_end
    return 0;
}

uint32_t pbw_api_gpoint_from_polar(pbw_ctx ctx, ARG_GRECT(rect), uint32_t scale_mode, int32_t angle) {
    return 0;
}

uint32_t pbw_api_grect_centered_from_polar(pbw_ctx ctx, uint32_t retptr, ARG_GRECT(rect), uint32_t scale_mode) {
    // stack: int32_t angle, GSize size
    return 0;
}

#pragma mark - Graphics Context

uint32_t pbw_api_graphics_context_set_stroke_color(pbw_ctx ctx, uint32_t gctx, uint32_t color) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    graphicsContext.strokeColor = [UIColor colorWithGColor:GColor(color & 0xff)];
    return 0;
}

uint32_t pbw_api_graphics_context_set_fill_color(pbw_ctx ctx, uint32_t gctx, uint32_t color) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    graphicsContext.fillColor = [UIColor colorWithGColor:GColor(color & 0xff)];
    return 0;
}

uint32_t pbw_api_graphics_context_set_text_color(pbw_ctx ctx, uint32_t gctx, uint32_t color) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    graphicsContext.textColor = [UIColor colorWithGColor:GColor(color & 0xff)];
    return 0;
}

uint32_t pbw_api_graphics_context_set_stroke_color_2bit(pbw_ctx ctx, uint32_t gctx, uint32_t color) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    graphicsContext.strokeColor = [UIColor colorWithGColor:GColorFrom2Bit(color & 0xff)];
    return 0;
}

uint32_t pbw_api_graphics_context_set_fill_color_2bit(pbw_ctx ctx, uint32_t gctx, uint32_t color) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    graphicsContext.fillColor = [UIColor colorWithGColor:GColorFrom2Bit(color & 0xff)];
    return 0;
}

uint32_t pbw_api_graphics_context_set_text_color_2bit(pbw_ctx ctx, uint32_t gctx, uint32_t color) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    graphicsContext.textColor = [UIColor colorWithGColor:GColorFrom2Bit(color & 0xff)];
    return 0;
}

uint32_t pbw_api_graphics_context_set_compositing_mode(pbw_ctx ctx, uint32_t gctx, uint32_t comp_op) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    graphicsContext.compositingMode = (comp_op & 0xff);
    return 0;
}

uint32_t pbw_api_graphics_context_set_antialiased(pbw_ctx ctx, uint32_t gctx, uint32_t enable) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    BOOL antialias = !!enable;
    graphicsContext.antialiased = antialias;
    CGContextSetInterpolationQuality(graphicsContext->cgContext, antialias ? kCGInterpolationDefault : kCGInterpolationNone);
    CGContextSetAllowsAntialiasing(graphicsContext->cgContext, antialias);
    CGContextSetAllowsFontSmoothing(graphicsContext->cgContext, antialias);
    return 0;
}

uint32_t pbw_api_graphics_context_set_stroke_width(pbw_ctx ctx, uint32_t gctx, uint32_t stroke_width) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    graphicsContext.strokeWidth = stroke_width & 0xff;
    return 0;
}


@implementation PBWGraphicsContext
{
    CGSize screenSize;
}

- (instancetype)initWithRuntime:(PBWRuntime *)rt {
    if (self = [super initWithRuntime:rt]) {
        screenSize = rt.screenSize;
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        cgContext = CGBitmapContextCreate(NULL, screenSize.width, screenSize.height, 5, screenSize.width * 2, cs, kCGImageByteOrder16Little | kCGImageAlphaNoneSkipFirst);
    }
    return self;
}

- (void)drawWindow:(PBWWindow*)window {
    [window.rootLayer drawLayerHierarchyInContext:self];
    CGImageRef image = CGBitmapContextCreateImage(cgContext);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, screenSize.width, screenSize.height), image);
    CGImageRelease(image);
    window->dirty = NO;
}

- (UIBezierPath*)pathWithGPath:(uint32_t)ptr {
    pbw_ctx ctx = self->_runtime.runtimeContext;
    void *gpath = pbw_ctx_get_pointer(ctx, ptr);
    uint32_t numPoints = OSReadLittleInt32(gpath, 0);
    void *points = pbw_ctx_get_pointer(ctx, OSReadLittleInt32(gpath, 4));
    int32_t rotation = OSReadLittleInt32(gpath, 8);
    GPoint offset = UNPACK_POINT(OSReadLittleInt32(gpath, 12));
    UIBezierPath *path = [[UIBezierPath alloc] init];
    CGPoint nextPoint = CGPointFromGPoint(UNPACK_POINT(OSReadLittleInt32(points, 0)));
    [path moveToPoint:nextPoint];
    for (int i = 1; i < numPoints; i++) {
        nextPoint = CGPointFromGPoint(UNPACK_POINT(OSReadLittleInt32(points, 4*i)));
        [path addLineToPoint:nextPoint];
    }
    if (offset.x || offset.y) {
        [path applyTransform:CGAffineTransformMakeTranslation(offset.x, offset.y)];
    }
    if (rotation) {
        [path applyTransform:CGAffineTransformMakeRotation(TRIG_TO_RADIANS(rotation))];
    }
    return path;
}

@end
