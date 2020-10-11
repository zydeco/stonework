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
#import "PBWBitmap.h"
#import "PBWFont.h"
#import <UIKit/UIKit.h>
#import "weemalloc.h"

#define ReadRAMPointer(p) (p ? p - ctx->ramBase : 0)
#define MakeRAMPointer(p) (p ? p + ctx->ramBase : 0)

CGColorRef PBWGraphicsCGColor[256];

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
    CGContextSetFillColorWithColor(cg, PBWGraphicsCGColor[graphicsContext.fillColor.argb]);
    CGContextSetStrokeColorWithColor(cg, PBWGraphicsCGColor[graphicsContext.fillColor.argb]);
    CGContextSetLineWidth(cg, 1.0);
    CGPathRef path = CGPathCreateFromHostGPath(ctx, pathPtr);
    CGContextAddPath(cg, path);
    CGContextClosePath(cg);
    CGContextDrawPath(cg, kCGPathFillStroke);
    CGPathRelease(path);
    return 0;
}

uint32_t pbw_api_gpath_draw_filled_legacy(pbw_ctx ctx, uint32_t gctx, uint32_t pathPtr) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    BOOL wasAntialiased = graphicsContext.antialiased;
    pbw_api_graphics_context_set_antialiased(ctx, gctx, false);
    pbw_api_gpath_draw_filled(ctx, gctx, pathPtr);
    if (wasAntialiased) pbw_api_graphics_context_set_antialiased(ctx, gctx, true);
    return 0;
}

uint32_t pbw_api_gpath_draw_outline(pbw_ctx ctx, uint32_t gctx, uint32_t pathPtr) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    CGContextRef cg = graphicsContext->cgContext;
    CGContextSetStrokeColorWithColor(cg, PBWGraphicsCGColor[graphicsContext.strokeColor.argb]);
    CGContextSetLineWidth(cg, graphicsContext.strokeWidth);
    CGPathRef path = CGPathCreateFromHostGPath(ctx, pathPtr);
    CGContextBeginPath(cg);
    CGContextAddPath(cg, path);
    CGContextClosePath(cg);
    CGContextStrokePath(cg);
    CGPathRelease(path);
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
    CGContextSetStrokeColorWithColor(cg, PBWGraphicsCGColor[graphicsContext.strokeColor.argb]);
    CGContextSetLineWidth(cg, graphicsContext.strokeWidth);
    CGPathRef path = CGPathCreateFromHostGPath(ctx, pathPtr);
    CGContextBeginPath(cg);
    CGContextAddPath(cg, path);
    CGContextStrokePath(cg);
    CGPathRelease(path);
    return 0;
}


#pragma mark - Drawing Primitives

uint32_t pbw_api_graphics_draw_pixel(pbw_ctx ctx, uint32_t gctx, uint32_t point_arg) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    CGContextRef cg = graphicsContext->cgContext;
    GPoint point = UNPACK_POINT(point_arg);
    CGContextSetFillColorWithColor(cg, PBWGraphicsCGColor[graphicsContext.fillColor.argb]);
    CGContextFillRect(cg, CGRectMake(point.x, point.y, 1, 1));
    return 0;
}

uint32_t pbw_api_graphics_draw_line(pbw_ctx ctx, uint32_t gctx, uint32_t p0, uint32_t p1) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    CGContextRef cg = graphicsContext->cgContext;
    GPoint point0 = UNPACK_POINT(p0);
    GPoint point1 = UNPACK_POINT(p1);
    CGContextBeginPath(cg);
    CGContextMoveToPoint(cg, point0.x, point0.y);
    CGContextAddLineToPoint(cg, point1.x, point1.y);
    CGContextSetStrokeColorWithColor(cg, PBWGraphicsCGColor[graphicsContext.strokeColor.argb]);
    CGContextSetLineWidth(cg, graphicsContext.strokeWidth);
    CGContextDrawPath(cg, kCGPathStroke);
    return 0;
}

uint32_t pbw_api_graphics_draw_rect(pbw_ctx ctx, uint32_t gctx, ARG_GRECT(rect)) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    CGContextRef cg = graphicsContext->cgContext;
    CGContextSetStrokeColorWithColor(cg, PBWGraphicsCGColor[graphicsContext.strokeColor.argb]);
    CGContextSetLineWidth(cg, 1.0);
    CGRect rect = CGRectFromGRect(UNPACK_GRECT(rect));
    CGContextStrokeRect(cg, rect);
    return 0;
}

uint32_t pbw_api_graphics_fill_rect(pbw_ctx ctx, uint32_t gctx, ARG_GRECT(rect), uint32_t corner_radius) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    CGContextRef cg = graphicsContext->cgContext;
    CGRect rect = CGRectInset(CGRectFromGRect(UNPACK_GRECT(rect)), 0.0, 0.0);
    corner_radius &= 0xffff;
    UIRectCorner corners = pbw_cpu_stack_peek(ctx->cpu, 0) & 0xf; // coincidentally, same format
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:corners cornerRadii:CGSizeMake(corner_radius, corner_radius)];
    CGContextSetFillColorWithColor(cg, PBWGraphicsCGColor[graphicsContext.fillColor.argb]);
    CGContextBeginPath(cg);
    CGContextAddPath(cg, path.CGPath);
    CGContextFillPath(cg);
    return 0;
}

uint32_t pbw_api_graphics_draw_circle(pbw_ctx ctx, uint32_t gctx, uint32_t center, uint32_t radius) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    CGContextRef cg = graphicsContext->cgContext;
    GPoint centerPoint = UNPACK_POINT(center);
    CGRect rect = CGRectMake(centerPoint.x - radius, centerPoint.y - radius, 2*radius, 2*radius);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:rect];
    CGContextSetStrokeColorWithColor(cg, PBWGraphicsCGColor[graphicsContext.strokeColor.argb]);
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
    CGRect rect = CGRectMake(centerPoint.x - radius, centerPoint.y - radius, 2*radius, 2*radius);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:rect];
    CGContextSetFillColorWithColor(cg, PBWGraphicsCGColor[graphicsContext.fillColor.argb]);
    CGContextBeginPath(cg);
    CGContextAddPath(cg, path.CGPath);
    CGContextFillPath(cg);
    return 0;
}

uint32_t pbw_api_graphics_draw_round_rect(pbw_ctx ctx, uint32_t gctx, ARG_GRECT(rect), uint32_t corner_radius) {
    // TODO: implement
    return 0;
}

uint32_t pbw_api_graphics_draw_bitmap_in_rect(pbw_ctx ctx, uint32_t gctx, uint32_t bitmapPtr, ARG_GRECT(rect)) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    PBWBitmap *bitmap = ctx->runtime.objects[@(bitmapPtr)];
    [bitmap drawInRect:UNPACK_GRECT(rect) context:graphicsContext];
    return 0;
}

uint32_t pbw_api_graphics_draw_arc(pbw_ctx ctx, uint32_t gctx, ARG_GRECT(rect), uint32_t scale_mode) {
    // stack: int32_t angle_start, int32_t angle_end
    // TODO: implement
    return 0;
}

uint32_t pbw_api_graphics_fill_radial(pbw_ctx ctx, uint32_t gctx, ARG_GRECT(rect), uint32_t scale_mode) {
    // stack: uint16_t inset_thickness, int32_t angle_start, int32_t angle_end
    // TODO: implement
    return 0;
}

uint32_t pbw_api_gpoint_from_polar(pbw_ctx ctx, ARG_GRECT(rect), uint32_t scale_mode, int32_t angle) {
    // TODO: implement
    return 0;
}

uint32_t pbw_api_grect_centered_from_polar(pbw_ctx ctx, uint32_t retptr, ARG_GRECT(rect), uint32_t scale_mode) {
    // stack: int32_t angle, GSize size
    // TODO: implement
    return 0;
}

#pragma mark - Graphics Context

uint32_t pbw_api_graphics_context_set_stroke_color(pbw_ctx ctx, uint32_t gctx, uint32_t color) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    graphicsContext.strokeColor = GColor(color & 0xff);
    return 0;
}

uint32_t pbw_api_graphics_context_set_fill_color(pbw_ctx ctx, uint32_t gctx, uint32_t color) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    graphicsContext.fillColor = GColor(color & 0xff);
    return 0;
}

uint32_t pbw_api_graphics_context_set_text_color(pbw_ctx ctx, uint32_t gctx, uint32_t color) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    graphicsContext.textColor = GColor(color & 0xff);
    return 0;
}

uint32_t pbw_api_graphics_context_set_stroke_color_2bit(pbw_ctx ctx, uint32_t gctx, uint32_t color) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    graphicsContext.strokeColor = GColorFrom2Bit(color & 0xff);
    return 0;
}

uint32_t pbw_api_graphics_context_set_fill_color_2bit(pbw_ctx ctx, uint32_t gctx, uint32_t color) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    graphicsContext.fillColor = GColorFrom2Bit(color & 0xff);
    return 0;
}

uint32_t pbw_api_graphics_context_set_text_color_2bit(pbw_ctx ctx, uint32_t gctx, uint32_t color) {
    PBWGraphicsContext *graphicsContext = ctx->runtime.objects[@(gctx)];
    graphicsContext.textColor = GColorFrom2Bit(color & 0xff);
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

const uint32_t PBWGraphicsNativePalette[256] = {
    0xff000000,0xff000055,0xff0000aa,0xff0000ff,0xff005500,0xff005555,0xff0055aa,0xff0055ff,
    0xff00aa00,0xff00aa55,0xff00aaaa,0xff00aaff,0xff00ff00,0xff00ff55,0xff00ffaa,0xff00ffff,
    0xff550000,0xff550055,0xff5500aa,0xff5500ff,0xff555500,0xff555555,0xff5555aa,0xff5555ff,
    0xff55aa00,0xff55aa55,0xff55aaaa,0xff55aaff,0xff55ff00,0xff55ff55,0xff55ffaa,0xff55ffff,
    0xffaa0000,0xffaa0055,0xffaa00aa,0xffaa00ff,0xffaa5500,0xffaa5555,0xffaa55aa,0xffaa55ff,
    0xffaaaa00,0xffaaaa55,0xffaaaaaa,0xffaaaaff,0xffaaff00,0xffaaff55,0xffaaffaa,0xffaaffff,
    0xffff0000,0xffff0055,0xffff00aa,0xffff00ff,0xffff5500,0xffff5555,0xffff55aa,0xffff55ff,
    0xffffaa00,0xffffaa55,0xffffaaaa,0xffffaaff,0xffffff00,0xffffff55,0xffffffaa,0xffffffff,
    0xff000000,0xff000055,0xff0000aa,0xff0000ff,0xff005500,0xff005555,0xff0055aa,0xff0055ff,
    0xff00aa00,0xff00aa55,0xff00aaaa,0xff00aaff,0xff00ff00,0xff00ff55,0xff00ffaa,0xff00ffff,
    0xff550000,0xff550055,0xff5500aa,0xff5500ff,0xff555500,0xff555555,0xff5555aa,0xff5555ff,
    0xff55aa00,0xff55aa55,0xff55aaaa,0xff55aaff,0xff55ff00,0xff55ff55,0xff55ffaa,0xff55ffff,
    0xffaa0000,0xffaa0055,0xffaa00aa,0xffaa00ff,0xffaa5500,0xffaa5555,0xffaa55aa,0xffaa55ff,
    0xffaaaa00,0xffaaaa55,0xffaaaaaa,0xffaaaaff,0xffaaff00,0xffaaff55,0xffaaffaa,0xffaaffff,
    0xffff0000,0xffff0055,0xffff00aa,0xffff00ff,0xffff5500,0xffff5555,0xffff55aa,0xffff55ff,
    0xffffaa00,0xffffaa55,0xffffaaaa,0xffffaaff,0xffffff00,0xffffff55,0xffffffaa,0xffffffff,
    0xff000000,0xff000055,0xff0000aa,0xff0000ff,0xff005500,0xff005555,0xff0055aa,0xff0055ff,
    0xff00aa00,0xff00aa55,0xff00aaaa,0xff00aaff,0xff00ff00,0xff00ff55,0xff00ffaa,0xff00ffff,
    0xff550000,0xff550055,0xff5500aa,0xff5500ff,0xff555500,0xff555555,0xff5555aa,0xff5555ff,
    0xff55aa00,0xff55aa55,0xff55aaaa,0xff55aaff,0xff55ff00,0xff55ff55,0xff55ffaa,0xff55ffff,
    0xffaa0000,0xffaa0055,0xffaa00aa,0xffaa00ff,0xffaa5500,0xffaa5555,0xffaa55aa,0xffaa55ff,
    0xffaaaa00,0xffaaaa55,0xffaaaaaa,0xffaaaaff,0xffaaff00,0xffaaff55,0xffaaffaa,0xffaaffff,
    0xffff0000,0xffff0055,0xffff00aa,0xffff00ff,0xffff5500,0xffff5555,0xffff55aa,0xffff55ff,
    0xffffaa00,0xffffaa55,0xffffaaaa,0xffffaaff,0xffffff00,0xffffff55,0xffffffaa,0xffffffff,
    0xff000000,0xff000055,0xff0000aa,0xff0000ff,0xff005500,0xff005555,0xff0055aa,0xff0055ff,
    0xff00aa00,0xff00aa55,0xff00aaaa,0xff00aaff,0xff00ff00,0xff00ff55,0xff00ffaa,0xff00ffff,
    0xff550000,0xff550055,0xff5500aa,0xff5500ff,0xff555500,0xff555555,0xff5555aa,0xff5555ff,
    0xff55aa00,0xff55aa55,0xff55aaaa,0xff55aaff,0xff55ff00,0xff55ff55,0xff55ffaa,0xff55ffff,
    0xffaa0000,0xffaa0055,0xffaa00aa,0xffaa00ff,0xffaa5500,0xffaa5555,0xffaa55aa,0xffaa55ff,
    0xffaaaa00,0xffaaaa55,0xffaaaaaa,0xffaaaaff,0xffaaff00,0xffaaff55,0xffaaffaa,0xffaaffff,
    0xffff0000,0xffff0055,0xffff00aa,0xffff00ff,0xffff5500,0xffff5555,0xffff55aa,0xffff55ff,
    0xffffaa00,0xffffaa55,0xffffaaaa,0xffffaaff,0xffffff00,0xffffff55,0xffffffaa,0xffffffff
};

const char* PBWGraphicsColorName[64] = {
    "Black",
    "OxfordBlue",
    "DukeBlue",
    "Blue",
    "DarkGreen",
    "MidnightGreen",
    "CobaltBlue",
    "BlueMoon",
    "IslamicGreen",
    "JaegerGreen",
    "TiffanyBlue",
    "VividCerulean",
    "Green",
    "Malachite",
    "MediumSpringGreen",
    "Cyan",
    "BulgarianRose",
    "ImperialPurple",
    "Indigo",
    "ElectricUltramarine",
    "ArmyGreen",
    "DarkGray",
    "Liberty",
    "VeryLightBlue",
    "KellyGreen",
    "MayGreen",
    "CadetBlue",
    "PictonBlue",
    "BrightGreen",
    "ScreaminGreen",
    "MediumAquamarine",
    "ElectricBlue",
    "DarkCandyAppleRed",
    "JazzberryJam",
    "Purple",
    "VividViolet",
    "WindsorTan",
    "RoseVale",
    "Purpureus",
    "LavenderIndigo",
    "Limerick",
    "Brass",
    "LightGray",
    "BabyBlueEyes",
    "SpringBud",
    "Inchworm",
    "MintGreen",
    "Celeste",
    "Red",
    "Folly",
    "FashionMagenta",
    "Magenta",
    "Orange",
    "SunsetOrange",
    "BrilliantRose",
    "ShockingPink",
    "ChromeYellow",
    "Rajah",
    "Melon",
    "RichBrilliantLavender",
    "Yellow",
    "Icterine",
    "PastelYellow",
    "White"
};

@implementation PBWGraphicsContext
{
    CGSize screenSize;
}

+ (void)load {
    // I'm scared of floating point literals
    CGFloat values[4] = {0.0, 1.0 / (CGFloat)3.0, 2.0 / (CGFloat)3.0, 1.0};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    for (NSUInteger i=0; i < 256; i++) {
        NSUInteger a = (i >> 6) & 3;
        NSUInteger r = (i >> 4) & 3;
        NSUInteger g = (i >> 2) & 3;
        NSUInteger b = i & 3;
        CGFloat components[4] = {values[r], values[g], values[b], values[a]};
        PBWGraphicsCGColor[i] = CGColorCreate(colorSpace, components);
    }
}

- (instancetype)initWithRuntime:(PBWRuntime *)rt {
    if (self = [super initWithRuntime:rt]) {
        screenSize = rt.screenSize;
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        cgContext = CGBitmapContextCreate(NULL, screenSize.width, screenSize.height, 8, screenSize.width * 4, cs, kCGImageByteOrder32Little | kCGImageAlphaNoneSkipFirst);
        CGColorSpaceRelease(cs);
        _strokeWidth = 1;
    }
    return self;
}

- (void)drawWindow:(PBWWindow*)window {
    [window.rootLayer drawLayerHierarchyInContext:self];
}

- (void)setPixel:(GPoint)pixel toColor:(GColor8)color {
    uint32_t *fbuf = CGBitmapContextGetData(cgContext);
    uint32_t rowWidth = screenSize.width;
    uint32_t screenHeight = screenSize.height;
    fbuf[pixel.x + (screenHeight - pixel.y) * rowWidth] = PBWGraphicsNativePalette[color.argb | 0xc0];
}

@end
