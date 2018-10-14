//
//  PBWGraphics.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 05/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWGraphics.h"

#define GRectPtrMinX(rect) (rect->origin.x)
#define GRectPtrMaxX(rect) (rect->origin.x + rect->size.w)
#define GRectPtrMinY(rect) (rect->origin.y)
#define GRectPtrMaxY(rect) (rect->origin.y + rect->size.h)
#define MAX(a,b) (((a) >= (b)) ? (a) : (b))
#define MIN(a,b) (((a) <= (b)) ? (a) : (b))

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
    return rect->size.h <= 0 || rect->size.w <= 0;
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
