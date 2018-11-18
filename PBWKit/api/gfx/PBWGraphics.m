//
//  PBWGraphics.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 05/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWGraphics.h"
#import "PBWRuntime.h"

#define GRectPtrMinX(rect) (rect->origin.x)
#define GRectPtrMaxX(rect) (rect->origin.x + rect->size.w)
#define GRectPtrMinY(rect) (rect->origin.y)
#define GRectPtrMaxY(rect) (rect->origin.y + rect->size.h)

bool gpoint_equal(const GPoint * const point_a, const GPoint * const point_b) {
    return point_a->x == point_b->x && point_a->y == point_b->y;
}

bool gsize_equal(const GSize *size_a, const GSize *size_b) {
    return size_a->w == size_b->w && size_a->h == size_b->w;
}

bool grect_equal(const GRect* const rect_a, const GRect* const rect_b) {
    const GPoint * const point_a = &rect_a->origin;
    const GPoint * const point_b = &rect_b->origin;
    const GSize * const size_a = &rect_a->size;
    const GSize * const size_b = &rect_b->size;
    return point_a->x == point_b->x && point_a->y == point_b->y && size_a->w == size_b->w && size_a->h == size_b->w;
}

bool grect_is_empty(const GRect* const rect) {
    GSize size = rect->size;
    return (size.h == 0 && size.w == 0) || size.h < 0 || size.w < 0;
}

void grect_standardize(GRect *rect) {
    if (rect->size.w < 0) {
        rect->origin.x += rect->size.w;
        rect->size.w *= -1;
    }
    if (rect->size.h < 0) {
        rect->origin.y += rect->size.h;
        rect->size.h *= -1;
    }
}

void grect_clip(GRect * const rect_to_clip, const GRect * const rect_clipper) {
    // I think this means intersect
    
    if (GRectPtrMaxX(rect_to_clip) <= GRectPtrMinX(rect_clipper) ||
        GRectPtrMinX(rect_to_clip) >= GRectPtrMaxX(rect_clipper) ||
        GRectPtrMaxY(rect_to_clip) <= GRectPtrMinY(rect_clipper) ||
        GRectPtrMinY(rect_clipper) >= GRectPtrMaxY(rect_clipper)) {
        *rect_to_clip = GRectZero;
        return;
    };
    
    rect_to_clip->origin.x = MAX(GRectPtrMinX(rect_to_clip), GRectPtrMinX(rect_clipper));
    rect_to_clip->origin.y = MAX(GRectPtrMinY(rect_to_clip), GRectPtrMinY(rect_clipper));
    rect_to_clip->size.w = MIN(GRectPtrMaxX(rect_to_clip), GRectPtrMaxX(rect_clipper)) - rect_to_clip->origin.x;
    rect_to_clip->size.h = MIN(GRectPtrMaxY(rect_to_clip), GRectPtrMaxY(rect_clipper)) - rect_to_clip->origin.y;
}

bool grect_contains_point(const GRect *rect, const GPoint *point) {
    return point->x >= rect->origin.x && point->x <= (rect->origin.x + rect->size.w) && point->y >= rect->origin.y && point->y <= (rect->origin.y + rect->size.h);
}

GPoint grect_center_point(const GRect *rect) {
    return GPoint(rect->origin.x + rect->size.w / 2, rect->origin.y + rect->size.h / 2);
}

GRect grect_crop(GRect rect, const int32_t crop_size_px) {
    rect.origin.x += crop_size_px / 2;
    rect.origin.y += crop_size_px / 2;
    rect.size.w -= crop_size_px;
    rect.size.h -= crop_size_px;
    return rect;
}

void grect_align(GRect * rect, const GRect * inside_rect, GAlign alignment, bool clip) {
    int16_t widthDiff = inside_rect->size.w - rect->size.w;
    int16_t heightDiff = inside_rect->size.h - rect->size.h;
    switch (alignment) {
        case GAlignCenter:
            rect->origin.x = inside_rect->origin.x + (widthDiff / 2);
            rect->origin.y = inside_rect->origin.y + (heightDiff / 2);
            break;
        case GAlignTopLeft:
            rect->origin = inside_rect->origin;
            break;
        case GAlignTopRight:
            rect->origin.x = inside_rect->origin.x + widthDiff;
            rect->origin.y = inside_rect->origin.y;
            break;
        case GAlignTop:
            rect->origin.x = inside_rect->origin.x + (widthDiff / 2);
            rect->origin.y = inside_rect->origin.y;
            break;
        case GAlignLeft:
            rect->origin.x = inside_rect->origin.x;
            rect->origin.y = inside_rect->origin.y + (heightDiff / 2);
            break;
        case GAlignBottom:
            rect->origin.x = inside_rect->origin.x + (widthDiff / 2);
            rect->origin.y = inside_rect->origin.y + heightDiff;
            break;
        case GAlignRight:
            rect->origin.x = inside_rect->origin.x + widthDiff;
            rect->origin.y = inside_rect->origin.y + (heightDiff / 2);
            break;
        case GAlignBottomRight:
            rect->origin.x = inside_rect->origin.x + widthDiff;
            rect->origin.y = inside_rect->origin.y + heightDiff;
            break;
        case GAlignBottomLeft:
            rect->origin.x = inside_rect->origin.x;
            rect->origin.y = inside_rect->origin.y + heightDiff;
            break;
    }
    if (clip) {
        grect_clip(rect, inside_rect);
    }
}

GRect grect_inset(GRect rect, GEdgeInsets insets) {
    GRect dstRect = rect;
    if (insets.top) {
        dstRect.origin.y += insets.top;
        dstRect.size.h -= insets.top;
    }
    if (insets.left) {
        dstRect.origin.x += insets.left;
        dstRect.size.w -= insets.left;
    }
    if (insets.right) {
        dstRect.size.w -= insets.right;
    }
    if (insets.bottom) {
        dstRect.size.h -= insets.bottom;
    }
    return dstRect;
}

bool gcolor_equal(GColor8 x, GColor8 y) {
    return ((x.argb | y.argb) & 0b11000000) ? x.argb == y.argb : true;
}

GColor8 gcolor_legible_over(GColor8 background_color) {
    uint8_t argb = background_color.argb;
    uint8_t alphaBits = ((argb >> 6) & 0x03);
    uint8_t redBits = ((argb >> 4) & 0x03);
    uint8_t greenBits = ((argb >> 2) & 0x03);
    uint8_t blueBits = (argb & 0x03);
    if (alphaBits < 0b10) {
        return GColorClear;
    } else if (greenBits > 0b01 || (greenBits == 0b01 && (redBits == 0b11 || (blueBits == 0b11 && redBits >= 0b10)))) {
        return GColorBlack;
    } else {
        return GColorWhite;
    }
}

uint32_t pbw_api_gcolor_equal(pbw_ctx ctx, uint32_t x, uint32_t y) {
    GColor8 cx = {.argb=(x & 0xff)};
    GColor8 cy = {.argb=(y & 0xff)};
    return gcolor_equal(cx, cy);
}

uint32_t pbw_api_gcolor_legible_over(pbw_ctx ctx, uint32_t background_color) {
    GColor8 c = {.argb=(background_color & 0xff)};
    return gcolor_legible_over(c).argb;
}

uint32_t pbw_api_gpoint_equal(pbw_ctx ctx, uint32_t aptr, uint32_t bptr) {
    GPoint a = UNPACK_POINT(pbw_cpu_read_word(ctx->cpu, aptr));
    GPoint b = UNPACK_POINT(pbw_cpu_read_word(ctx->cpu, bptr));
    return gpoint_equal(&a, &b);
}

uint32_t pbw_api_gsize_equal(pbw_ctx ctx, uint32_t aptr, uint32_t bptr) {
    GSize a = UNPACK_SIZE(pbw_cpu_read_word(ctx->cpu, aptr));
    GSize b = UNPACK_SIZE(pbw_cpu_read_word(ctx->cpu, bptr));
    return gsize_equal(&a, &b);
}

uint32_t pbw_api_grect_equal(pbw_ctx ctx, uint32_t aptr, uint32_t bptr) {
    GRect a = {
        .origin = UNPACK_POINT(pbw_cpu_read_word(ctx->cpu, aptr)),
        .size = UNPACK_SIZE(pbw_cpu_read_word(ctx->cpu, aptr+4))
    };
    GRect b = {
        .origin = UNPACK_POINT(pbw_cpu_read_word(ctx->cpu, bptr)),
        .size = UNPACK_SIZE(pbw_cpu_read_word(ctx->cpu, bptr+4))
    };
    return grect_equal(&a, &b);
}

uint32_t pbw_api_grect_is_empty(pbw_ctx ctx, uint32_t ptr) {
    GRect rect = {
        .origin = GPointZero,
        .size = UNPACK_SIZE(pbw_cpu_read_word(ctx->cpu, ptr+4))
    };
    return grect_is_empty(&rect);
}

uint32_t pbw_api_grect_standardize(pbw_ctx ctx, uint32_t ptr) {
    GRect rect = {
        .origin = UNPACK_POINT(pbw_cpu_read_word(ctx->cpu, ptr)),
        .size = UNPACK_SIZE(pbw_cpu_read_word(ctx->cpu, ptr+4))
    };
    grect_standardize(&rect);
    pbw_cpu_mem_write(ctx->cpu, ptr, PBW_MEM_WORD, PACK_POINT(rect.origin));
    pbw_cpu_mem_write(ctx->cpu, ptr+4, PBW_MEM_WORD, PACK_SIZE(rect.size));
    return 0;
}

uint32_t pbw_api_grect_clip(pbw_ctx ctx, uint32_t rect_ptr, uint32_t clip_ptr) {
    GRect rect = {
        .origin = UNPACK_POINT(pbw_cpu_read_word(ctx->cpu, rect_ptr)),
        .size = UNPACK_SIZE(pbw_cpu_read_word(ctx->cpu, rect_ptr+4))
    };
    GRect clip = {
        .origin = UNPACK_POINT(pbw_cpu_read_word(ctx->cpu, clip_ptr)),
        .size = UNPACK_SIZE(pbw_cpu_read_word(ctx->cpu, clip_ptr+4))
    };
    grect_clip(&rect, &clip);
    pbw_cpu_mem_write(ctx->cpu, rect_ptr, PBW_MEM_WORD, PACK_POINT(rect.origin));
    pbw_cpu_mem_write(ctx->cpu, rect_ptr+4, PBW_MEM_WORD, PACK_SIZE(rect.size));
    return 0;
}

uint32_t pbw_api_grect_contains_point(pbw_ctx ctx, uint32_t rect_ptr, uint32_t point_ptr) {
    GRect rect = {
        .origin = UNPACK_POINT(pbw_cpu_read_word(ctx->cpu, rect_ptr)),
        .size = UNPACK_SIZE(pbw_cpu_read_word(ctx->cpu, rect_ptr+4))
    };
    GPoint point = UNPACK_POINT(pbw_cpu_read_word(ctx->cpu, point_ptr));
    return grect_contains_point(&rect, &point);
}

uint32_t pbw_api_grect_center_point(pbw_ctx ctx, uint32_t rect_ptr) {
    GRect rect = {
        .origin = UNPACK_POINT(pbw_cpu_read_word(ctx->cpu, rect_ptr)),
        .size = UNPACK_SIZE(pbw_cpu_read_word(ctx->cpu, rect_ptr+4))
    };
    return PACK_POINT(grect_center_point(&rect));
}

uint32_t pbw_api_grect_crop(pbw_ctx ctx, uint32_t retptr, ARG_GRECT(rect), int32_t crop_size) {
    GRect rect = UNPACK_GRECT(rect);
    GRect croppedRect = grect_crop(rect, crop_size);
    RETURN_GRECT(croppedRect);
    return 0;
}

uint32_t pbw_api_grect_align(pbw_ctx ctx, uint32_t rect_ptr, uint32_t inside_rect_ptr, uint32_t alignment, uint32_t clip) {
    GRect rect = {
        .origin = UNPACK_POINT(pbw_cpu_read_word(ctx->cpu, rect_ptr)),
        .size = UNPACK_SIZE(pbw_cpu_read_word(ctx->cpu, rect_ptr+4))
    };
    GRect insideRect = {
        .origin = UNPACK_POINT(pbw_cpu_read_word(ctx->cpu, inside_rect_ptr)),
        .size = UNPACK_SIZE(pbw_cpu_read_word(ctx->cpu, inside_rect_ptr+4))
    };
    grect_align(&rect, &insideRect, MIN(alignment & 0xff, 8), clip & 0xff);
    pbw_cpu_mem_write(ctx->cpu, rect_ptr, PBW_MEM_WORD, PACK_POINT(rect.origin));
    pbw_cpu_mem_write(ctx->cpu, rect_ptr+4, PBW_MEM_WORD, PACK_SIZE(rect.size));
    return 0;
}

uint32_t pbw_api_grect_inset(pbw_ctx ctx, uint32_t retptr, ARG_GRECT(rect)) {
    GPoint topRight = UNPACK_POINT(pbw_cpu_reg_get(ctx->cpu, 3));
    GPoint bottomLeft = UNPACK_POINT(pbw_cpu_stack_peek(ctx->cpu, 0));
    GEdgeInsets insets = {
        .top = topRight.x,
        .right = topRight.y,
        .bottom = bottomLeft.x,
        .left = bottomLeft.y
    };
    GRect dstRect = grect_inset(UNPACK_GRECT(rect), insets);
    RETURN_GRECT(dstRect);
    return 0;
}
