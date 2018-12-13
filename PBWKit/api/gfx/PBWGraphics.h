//
//  PBWGraphics.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 05/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#ifndef PBWGraphics_h
#define PBWGraphics_h

#import <inttypes.h>
#import <stdbool.h>
#import <CoreGraphics/CoreGraphics.h>
#import <math.h>
#import "api.h"

typedef union GColor8 {
    uint8_t argb;
} GColor8;

typedef GColor8 GColor;

#include "gcolor_definitions.h"

typedef struct __attribute__((__packed__)) GPoint {
    int16_t x;
    int16_t y;
} GPoint;

#define GPoint(x, y) ((GPoint){(x), (y)})
#define GPointZero GPoint(0, 0)

static inline CGPoint CGPointFromGPoint(GPoint point) {
    return CGPointMake(point.x, point.y);
}

bool gpoint_equal(const GPoint * const point_a, const GPoint * const point_b);

typedef struct  GSize {
    int16_t w;
    int16_t h;
} GSize;

#define GSize(w, h) ((GSize){(w), (h)})
#define GSizeZero GSize(0, 0)

static inline CGSize CGSizeFromGSize(GSize size) {
    return CGSizeMake(size.w, size.h);
}

bool gsize_equal(const GSize *size_a, const GSize *size_b);

typedef struct GRect {
    GPoint origin;
    GSize size;
} GRect;

#define GRect(x, y, w, h) ((GRect){{(x), (y)}, {(w), (h)}})
#define GRectZero GRect(0, 0, 0, 0)

typedef struct {
    int16_t top, right;
    int16_t bottom, left;
} GEdgeInsets;

typedef enum GAlign {
    GAlignCenter,
    GAlignTopLeft,
    GAlignTopRight,
    GAlignTop,
    GAlignLeft,
    GAlignBottom,
    GAlignRight,
    GAlignBottomRight,
    GAlignBottomLeft
} GAlign;

bool grect_equal(const GRect* const rect_a, const GRect* const rect_b);
bool grect_is_empty(const GRect* const rect);
void grect_standardize(GRect *rect);
void grect_clip(GRect * const rect_to_clip, const GRect * const rect_clipper);
bool grect_contains_point(const GRect *rect, const GPoint *point);
GPoint grect_center_point(const GRect *rect);
GRect grect_crop(GRect rect, const int32_t crop_size_px);
void grect_align(GRect * rect, const GRect * inside_rect, GAlign alignment, bool clip);
GRect grect_inset(GRect rect, GEdgeInsets insets);

static inline CGRect CGRectFromGRect(GRect rect) {
    return CGRectMake(rect.origin.x, rect.origin.y, rect.size.w, rect.size.h);
}

static inline GRect GRectFromCGRect(CGRect rect) {
    return GRect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

#define NSStringFromGRect(rect) (NSStringFromCGRect(CGRectFromGRect(rect)))

typedef enum {
    //! Assign the pixel values of the source image to the destination pixels,
    //! effectively replacing the previous values for those pixels. For color displays, when drawing
    //! a palettized or 8-bit \ref GBitmap image, the opacity value is ignored.
    GCompOpAssign,
    //! Assign the **inverted** pixel values of the source image to the destination pixels,
    //! effectively replacing the previous values for those pixels.
    //! @note For bitmaps with a format different from GBitmapFormat1Bit, this mode is not supported
    //!     and the resulting behavior is undefined.
    GCompOpAssignInverted,
    //! Use the boolean operator `OR` to composite the source and destination pixels.
    //! The visual result of this compositing mode is the source's white pixels
    //! are painted onto the destination and the source's black pixels are treated
    //! as clear.
    //! @note For bitmaps with a format different from GBitmapFormat1Bit, this mode is not supported
    //!     and the resulting behavior is undefined.
    GCompOpOr, // kCGBlendModeScreen
    //! Use the boolean operator `AND` to composite the source and destination pixels.
    //! The visual result of this compositing mode is the source's black pixels
    //! are painted onto the destination and the source's white pixels are treated
    //! as clear.
    //! @note For bitmaps with a format different from GBitmapFormat1Bit, this mode is not supported
    //!     and the resulting behavior is undefined.
    GCompOpAnd, // kCGBlendModeMultiply
    //! Clears the bits in the destination image, using the source image as mask.
    //! The visual result of this compositing mode is that for the parts where the source image is
    //! white, the destination image will be painted black. Other parts will be left untouched.
    //! @note For bitmaps with a format different from GBitmapFormat1Bit, this mode is not supported
    //!     and the resulting behavior is undefined.
    GCompOpClear,
    //! Sets the bits in the destination image, using the source image as mask.
    //! This mode is required to apply any transparency of your bitmap.
    //! @note For bitmaps of the format GBitmapFormat1Bit, the visual result of this compositing
    //!   mode is that for the parts where the source image is black, the destination image will be
    //!   painted white. Other parts will be left untouched.
    GCompOpSet,
} GCompOp;

typedef enum GBitmapFormat {
    GBitmapFormat1Bit = 0, // 1-bit black and white. 0 = black, 1 = white.
    GBitmapFormat8Bit,     // 6-bit color + 2 bit alpha channel. See \ref GColor8 for pixel format.
    GBitmapFormat1BitPalette,
    GBitmapFormat2BitPalette,
    GBitmapFormat4BitPalette,
    GBitmapFormat8BitCircular,
} GBitmapFormat;

#define PACK_POINT(p) (p.x | (p.y << 16))
#define PACK_SIZE(s) (s.w | (s.h << 16))
#define RETURN_GRECT(f) pbw_cpu_mem_write(ctx->cpu, retptr, PBW_MEM_WORD, PACK_POINT(f.origin)); pbw_cpu_mem_write(ctx->cpu, retptr+4, PBW_MEM_WORD, PACK_SIZE(f.size));
#define UNPACK_GRECT(name) GRect(name##_origin & 0xffff, name##_origin >> 16, name##_size & 0xffff, name##_size >> 16)
#define UNPACK_POINT(arg) GPoint(arg & 0xffff, arg >> 16)
#define UNPACK_SIZE(arg) GSize(arg & 0xffff, arg >> 16)

CGPathRef CGPathCreateFromHostGPath(pbw_ctx ctx, uint32_t ptr);

typedef enum GTextAlignment {
    GTextAlignmentLeft = 0,
    GTextAlignmentCenter,
    GTextAlignmentRight,
} GTextAlignment;

typedef enum GTextOverflowMode {
    GTextOverflowModeWordWrap = 0,
    GTextOverflowModeTrailingEllipsis,
    GTextOverflowModeFill
} GTextOverflowMode;

#endif /* PBWGraphics_h */
