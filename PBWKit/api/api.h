//
//  api.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 03/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#ifndef api_h
#define api_h

#import "../cpu/cpu.h"

@class UIView;
@class PBWObject, PBWRuntime;

struct pbw_ctx {
    pbw_cpu cpu;
    uint32_t appBase, appSize;
    uint32_t ramBase, ramSize;
    void *appSlice, *ramSlice;
    void *heapPtr;
    __weak PBWRuntime *runtime;
};

typedef struct pbw_ctx *pbw_ctx;

void* pbw_ctx_get_pointer(pbw_ctx ctx, uint32_t ptr);
uint32_t pbw_ctx_make_pointer(pbw_ctx ctx, void *ptr);

uint32_t pbw_api_call(pbw_cpu cpu, void *userData, uint32_t addr, pbw_mem_op op, pbw_mem_size size, uint32_t value);
typedef uint32_t (*pbw_api_impl)(pbw_ctx, ...);

#pragma mark - Pebble API

typedef enum : int32_t {
    //! Operation completed successfully.
    S_SUCCESS = 0,
    //! An error occurred (no description).
    E_ERROR = -1,
    //! No idea what went wrong.
    E_UNKNOWN = -2,
    //! There was a generic internal logic error.
    E_INTERNAL = -3,
    //! The function was not called correctly.
    E_INVALID_ARGUMENT = -4,
    //! Insufficient allocatable memory available.
    E_OUT_OF_MEMORY = -5,
    //! Insufficient long-term storage available.
    E_OUT_OF_STORAGE = -6,
    //! Insufficient resources available.
    E_OUT_OF_RESOURCES = -7,
    //! Argument out of range (may be dynamic).
    E_RANGE = -8,
    //! Target of operation does not exist.
    E_DOES_NOT_EXIST = -9,
    //! Operation not allowed (may depend on state).
    E_INVALID_OPERATION = -10,
    //! Another operation prevented this one.
    E_BUSY = -11,
    //! Operation not completed; try again.
    E_AGAIN = -12,
    //! Equivalent of boolean true.
    S_TRUE = 1,
    //! Equivalent of boolean false.
    S_FALSE = 0,
    //! For list-style requests.  At end of list.
    S_NO_MORE_ITEMS = 2,
    //! No action was taken as none was required.
    S_NO_ACTION_REQUIRED = 3,
} status_t;

typedef enum {
    //! Flag to represent the "seconds" time unit
    SECOND_UNIT = 1 << 0,
    //! Flag to represent the "minutes" time unit
    MINUTE_UNIT = 1 << 1,
    //! Flag to represent the "hours" time unit
    HOUR_UNIT = 1 << 2,
    //! Flag to represent the "days" time unit
    DAY_UNIT = 1 << 3,
    //! Flag to represent the "months" time unit
    MONTH_UNIT = 1 << 4,
    //! Flag to represent the "years" time unit
    YEAR_UNIT = 1 << 5
} TimeUnits;

#define PBW_API(name, ...) uint32_t pbw_api_##name(pbw_ctx ctx, ##__VA_ARGS__)
#define PROC_ARG(n) ((n < 4) ? pbw_cpu_reg_get(ctx->cpu, n) : pbw_cpu_stack_peek(ctx->cpu, n-4))

#pragma mark - Foundation / APP
PBW_API(app_event_loop);

#pragma mark - Foundation / App Message
PBW_API(app_message_open, uint32_t size_inbound, uint32_t size_outbound);
PBW_API(app_message_deregister_callbacks);
PBW_API(app_message_get_context);
PBW_API(app_message_set_context, uint32_t context);
PBW_API(app_message_register_inbox_received, uint32_t callback);
PBW_API(app_message_register_inbox_dropped, uint32_t callback);
PBW_API(app_message_register_outbox_sent, uint32_t callback);
PBW_API(app_message_register_outbox_failed, uint32_t callback);
PBW_API(app_message_inbox_size_maximum);
PBW_API(app_message_outbox_size_maximum);
PBW_API(app_message_outbox_begin, uint32_t iterator);
PBW_API(app_message_outbox_send);

#pragma mark - Foundation / Event Service
PBW_API(tick_timer_service_subscribe, uint32_t units, uint32_t handler);
PBW_API(tick_timer_service_unsubscribe);

#pragma mark - Foundation / Logging
PBW_API(app_log, uint32_t log_level, uint32_t filename_ptr, uint32_t line_number, uint32_t fmt_ptr);

#pragma mark - Foundation / Resource Manager
PBW_API(resource_get_handle, uint32_t resource_id);
PBW_API(resource_size, uint32_t handle);
PBW_API(resource_load, uint32_t handle, uint32_t buffer, uint32_t max_length);
PBW_API(resource_load_byte_range, uint32_t handle, uint32_t start_offset, uint32_t buffer, uint32_t num_bytes);

#pragma mark - Foundation / Storage
PBW_API(persist_exists, uint32_t key);
PBW_API(persist_get_size, uint32_t key);
PBW_API(persist_read_bool, uint32_t key);
PBW_API(persist_read_int, uint32_t key);
PBW_API(persist_read_data, uint32_t key, uint32_t buffer, int32_t buffer_size);
PBW_API(persist_read_string, uint32_t key, uint32_t buffer, int32_t buffer_size);
PBW_API(persist_write_bool, uint32_t key, uint32_t value);
PBW_API(persist_write_int, uint32_t key, int32_t value);
PBW_API(persist_write_data, uint32_t key, uint32_t data, int32_t size);
PBW_API(persist_write_string, uint32_t key, uint32_t cstring);
PBW_API(persist_delete, uint32_t key);

#pragma mark - Foundation / Wall Time
PBW_API(clock_is_24h_style);

#pragma mark - Graphics / Drawing Paths
PBW_API(gpath_create, uint32_t init);
PBW_API(gpath_destroy, uint32_t path);
PBW_API(gpath_draw_filled, uint32_t gctx, uint32_t path);
PBW_API(gpath_draw_filled_legacy, uint32_t gctx, uint32_t path);
PBW_API(gpath_draw_outline, uint32_t gctx, uint32_t path);
PBW_API(gpath_rotate_to, uint32_t path, int32_t angle);
PBW_API(gpath_move_to, uint32_t path, uint32_t point);
PBW_API(gpath_draw_outline_open, uint32_t gctx, uint32_t path);

#pragma mark - Graphics / Drawing Primitives
#define ARG_GRECT(name) uint32_t name##_origin, uint32_t name##_size
PBW_API(graphics_draw_pixel, uint32_t gctx, uint32_t point);
PBW_API(graphics_draw_line, uint32_t gctx, uint32_t p0, uint32_t p1);
PBW_API(graphics_draw_rect, uint32_t gctx, ARG_GRECT(rect));
PBW_API(graphics_fill_rect, uint32_t gctx, ARG_GRECT(rect), uint32_t corner_radius); // stack: corner_mask
PBW_API(graphics_draw_circle, uint32_t gctx, uint32_t center, uint32_t radius);
PBW_API(graphics_fill_circle, uint32_t gctx, uint32_t center, uint32_t radius);
PBW_API(graphics_draw_round_rect, uint32_t gctx, ARG_GRECT(rect), uint32_t corner_radius);
PBW_API(graphics_draw_bitmap_in_rect, uint32_t gctx, uint32_t bitmap, ARG_GRECT(rect));
PBW_API(graphics_draw_arc, uint32_t gctx, ARG_GRECT(rect), uint32_t scale_mode); // stack: int32_t angle_start, int32_t angle_end
PBW_API(graphics_fill_radial, uint32_t gctx, ARG_GRECT(rect), uint32_t scale_mode); // stack: uint16_t inset_thickness, int32_t angle_start, int32_t angle_end
PBW_API(gpoint_from_polar, ARG_GRECT(rect), uint32_t scale_mode, int32_t angle);
PBW_API(grect_centered_from_polar, uint32_t retptr, ARG_GRECT(rect), uint32_t scale_mode); // stack: int32_t angle, GSize size

#pragma mark - Graphics / Graphics Context
PBW_API(graphics_context_set_stroke_color, uint32_t gctx, uint32_t color);
PBW_API(graphics_context_set_fill_color, uint32_t gctx, uint32_t color);
PBW_API(graphics_context_set_text_color, uint32_t gctx, uint32_t color);
PBW_API(graphics_context_set_stroke_color_2bit, uint32_t gctx, uint32_t color);
PBW_API(graphics_context_set_fill_color_2bit, uint32_t gctx, uint32_t color);
PBW_API(graphics_context_set_text_color_2bit, uint32_t gctx, uint32_t color);
PBW_API(graphics_context_set_compositing_mode, uint32_t gctx, uint32_t comp_op);
PBW_API(graphics_context_set_antialiased, uint32_t gctx, uint32_t enable);
PBW_API(graphics_context_set_stroke_width, uint32_t gctx, uint32_t stroke_width);

#pragma mark - Graphics / Graphics Types
PBW_API(gcolor_equal, uint32_t x, uint32_t y);
PBW_API(gcolor_legible_over, uint32_t background_color);
PBW_API(gpoint_equal, uint32_t aptr, uint32_t bptr);
PBW_API(gsize_equal, uint32_t aptr, uint32_t bptr);
PBW_API(grect_equal, uint32_t aptr, uint32_t bptr);
PBW_API(grect_is_empty, uint32_t ptr);
PBW_API(grect_standardize, uint32_t ptr);
PBW_API(grect_clip, uint32_t rect_ptr, uint32_t clip_ptr);
PBW_API(grect_contains_point, uint32_t rect_ptr, uint32_t point_ptr);
PBW_API(grect_center_point, uint32_t rect_ptr);
PBW_API(grect_crop, uint32_t retptr, ARG_GRECT(rect), int32_t crop_size);
PBW_API(grect_align, uint32_t rect_ptr, uint32_t inside_rect_ptr, uint32_t alignment, uint32_t clip);
PBW_API(grect_inset, uint32_t retptr, ARG_GRECT(rect));

#pragma mark - User Interface / Layer
PBW_API(layer_create, ARG_GRECT(frame));
PBW_API(layer_create_with_data, ARG_GRECT(frame), uint32_t data_size);
PBW_API(layer_destroy, uint32_t layer);
PBW_API(layer_mark_dirty, uint32_t layer);
PBW_API(layer_set_update_proc, uint32_t layer, uint32_t callback);
PBW_API(layer_set_frame, uint32_t layer, ARG_GRECT(frame));
PBW_API(layer_get_frame, uint32_t retptr, uint32_t layer);
PBW_API(layer_set_bounds, uint32_t layer, ARG_GRECT(bounds));
PBW_API(layer_get_bounds, uint32_t retptr, uint32_t layer);
PBW_API(layer_convert_point_to_screen, uint32_t layer, uint32_t point);
PBW_API(layer_convert_rect_to_screen, uint32_t retptr, uint32_t layer, ARG_GRECT(frame));
PBW_API(layer_get_window, uint32_t layer);
PBW_API(layer_remove_from_parent, uint32_t layer);
PBW_API(layer_remove_child_layers, uint32_t layer);
PBW_API(layer_add_child, uint32_t layer, uint32_t child);
PBW_API(layer_insert_below_sibling, uint32_t layer_to_insert, uint32_t below_sibling_layer);
PBW_API(layer_insert_above_sibling, uint32_t layer_to_insert, uint32_t above_sibling_layer);
PBW_API(layer_set_hidden, uint32_t layer, uint32_t hidden);
PBW_API(layer_get_hidden, uint32_t layer);
PBW_API(layer_set_clips, uint32_t layer, uint32_t clips);
PBW_API(layer_get_clips, uint32_t layer);
PBW_API(layer_get_data, uint32_t layer);
PBW_API(layer_get_unobstructed_bounds, uint32_t retptr, uint32_t layer);

#pragma mark - User Interface / Window
PBW_API(window_create);
PBW_API(window_destroy, uint32_t window);
PBW_API(window_set_click_config_provider, uint32_t window, uint32_t click_config_provider);
PBW_API(window_set_click_config_provider_with_context, uint32_t window, uint32_t click_config_provider, uint32_t context);
PBW_API(window_get_click_config_provider, uint32_t window);
PBW_API(window_get_click_config_context, uint32_t window);
PBW_API(window_set_window_handlers, uint32_t window);
PBW_API(window_get_root_layer, uint32_t window);
PBW_API(window_set_background_color, uint32_t window, uint32_t color);
PBW_API(window_set_background_color_2bit, uint32_t window, uint32_t color);

#pragma mark - User Interface / Window Stack
PBW_API(window_stack_push, uint32_t window, uint32_t animated);

#pragma mark - Standard C / Memory

PBW_API(malloc, uint32_t size);
PBW_API(calloc, uint32_t count, uint32_t size);
PBW_API(realloc, uint32_t ptr, uint32_t size);
PBW_API(free, uint32_t ptr);
// memcmp is built into binaries
PBW_API(memcpy, uint32_t dst, uint32_t src, uint32_t size);
PBW_API(memmove, uint32_t dst, uint32_t src, uint32_t size);
PBW_API(memset, uint32_t dst, uint32_t c, uint32_t size);

#pragma mark - Standard C / String
PBW_API(strcmp, uint32_t s1, uint32_t s2);
PBW_API(strncmp, uint32_t s1, uint32_t s2, uint32_t n);
PBW_API(strcpy, uint32_t dst, uint32_t src);
PBW_API(strncpy, uint32_t dst, uint32_t src, uint32_t n);
PBW_API(strcat, uint32_t dst, uint32_t src);
PBW_API(strncat, uint32_t dst, uint32_t src, uint32_t n);
PBW_API(strlen, uint32_t str);
PBW_API(snprintf, uint32_t str, uint32_t n, uint32_t fmt);

#pragma mark - Standard C / Time
PBW_API(time, uint32_t ptr);
PBW_API(time__deprecated, uint32_t ptr);
PBW_API(localtime, uint32_t timep);
PBW_API(localtime__deprecated, uint32_t timep);
PBW_API(gmtime, uint32_t timep);
PBW_API(mktime, uint32_t tb);
PBW_API(time_ms, uint32_t timep, uint32_t msp);
PBW_API(time_start_of_today);

#endif /* api_h */
