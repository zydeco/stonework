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
typedef uint32_t (*pbw_api_impl)(pbw_ctx, uint32_t arg1, uint32_t arg2, uint32_t arg3, uint32_t arg4);

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

#define TRIG_MAX_RATIO 0xffff
#define TRIG_MAX_ANGLE 0x10000
#define TRIG_TO_RADIANS(t) ((2 * M_PI * t) / TRIG_MAX_ANGLE)
#define TRIGANGLE_TO_DEG(trig_angle) (((trig_angle) * 360) / TRIG_MAX_ANGLE)
#define DEG_TO_TRIGANGLE(angle) (((angle) * TRIG_MAX_ANGLE) / 360)

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

#pragma mark - Foundation / Event Service / AccelerometerService
PBW_API(accel_tap_service_subscribe, uint32_t handler);
PBW_API(accel_tap_service_unsubscribe);

#pragma mark - Foundation / Event Service / BatteryStateService
PBW_API(battery_state_service_subscribe, uint32_t handler);
PBW_API(battery_state_service_unsubscribe);
PBW_API(battery_state_service_peek);

#pragma mark - Foundation / Event Service / ConnectionService
PBW_API(connection_service_peek_pebble_app_connection);
PBW_API(connection_service_peek_pebblekit_connection);
PBW_API(connection_service_subscribe, uint32_t app_connection_handler, uint32_t pebblekit_connection_handler);
PBW_API(connection_service_unsubscribe);
PBW_API(bluetooth_connection_service_peek);
PBW_API(bluetooth_connection_service_subscribe, uint32_t handler);
PBW_API(bluetooth_connection_service_unsubscribe);

#pragma mark - Foundation / Event Service / TickTimerService
PBW_API(tick_timer_service_subscribe, uint32_t units, uint32_t handler);
PBW_API(tick_timer_service_unsubscribe);

#pragma mark - Foundation / Logging
PBW_API(app_log, uint32_t log_level, uint32_t filename_ptr, uint32_t line_number, uint32_t fmt_ptr);

#pragma mark - Foundation / Math
PBW_API(sin_lookup, uint32_t r_angle);
PBW_API(cos_lookup, uint32_t r_angle);
PBW_API(atan2_lookup, uint32_t ry, uint32_t rx);

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

#pragma mark - Graphics / Drawing Text
PBW_API(graphics_draw_text, uint32_t gctx, uint32_t textPtr, uint32_t fontTag, uint32_t box_origin); // stack: uint32_t box_size, uint32_t overflow_mode, uint32_t alignment, uint32_t text_attributes

#pragma mark - Graphics / Fonts
PBW_API(fonts_get_system_font, uint32_t font_key);
PBW_API(fonts_load_custom_font, uint32_t res_handle);
PBW_API(fonts_unload_custom_font, uint32_t font_handle);

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
PBW_API(gbitmap_get_bytes_per_row, uint32_t bitmap_ptr);
PBW_API(gbitmap_get_format, uint32_t bitmap_ptr);
PBW_API(gbitmap_get_data, uint32_t bitmap_ptr);
PBW_API(gbitmap_set_data, uint32_t bitmap_ptr, uint32_t data_ptr, uint32_t format, uint32_t row_size_bytes); // stack: bool free_on_destroy
PBW_API(gbitmap_get_bounds, uint32_t retptr, uint32_t bitmap_ptr);
PBW_API(gbitmap_set_bounds, uint32_t bitmap_ptr, ARG_GRECT(bounds));
PBW_API(gbitmap_get_palette, uint32_t bitmap_ptr);
PBW_API(gbitmap_set_palette, uint32_t bitmap_ptr, uint32_t palette_ptr, uint32_t free_on_destroy);
PBW_API(gbitmap_create_with_resource, uint32_t resource_id);
PBW_API(gbitmap_create_with_data, uint32_t data_ptr);
PBW_API(gbitmap_create_as_sub_bitmap, uint32_t base_bitmap_ptr, ARG_GRECT(sub_rect));
PBW_API(gbitmap_create_from_png_data, uint32_t png_ptr, uint32_t png_size);
PBW_API(gbitmap_create_blank, uint32_t size, uint32_t format);
PBW_API(gbitmap_create_blank_2bit, uint32_t size, uint32_t format);
PBW_API(gbitmap_create_blank_with_palette, uint32_t size, uint32_t format, uint32_t palette_ptr, uint32_t free_on_destroy);
PBW_API(gbitmap_create_palettized_from_1bit, uint32_t src_bitmap_ptr);
PBW_API(gbitmap_destroy, uint32_t bitmap_ptr);
PBW_API(gbitmap_get_data_row_info, uint32_t retptr, uint32_t bitmap_ptr, uint32_t y);

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

#pragma mark - User Interface / Layer / BitmapLayer
PBW_API(bitmap_layer_create, ARG_GRECT(frame));
PBW_API(bitmap_layer_destroy, uint32_t layer);
PBW_API(bitmap_layer_get_layer, uint32_t layer);
PBW_API(bitmap_layer_get_bitmap, uint32_t layer);
PBW_API(bitmap_layer_set_bitmap, uint32_t layer, uint32_t bitmap);
PBW_API(bitmap_layer_set_alignment, uint32_t layer, uint32_t alignment);
PBW_API(bitmap_layer_set_background_color, uint32_t layer, uint32_t color);
PBW_API(bitmap_layer_set_background_color_2bit, uint32_t layer, uint32_t color);
PBW_API(bitmap_layer_set_compositing_mode, uint32_t layer, uint32_t mode);

#pragma mark - User Interface / Layer / TextLayer
PBW_API(text_layer_create, ARG_GRECT(frame));
PBW_API(text_layer_destroy, uint32_t layer);
PBW_API(text_layer_get_layer, uint32_t layer);
PBW_API(text_layer_set_text, uint32_t layer, uint32_t text);
PBW_API(text_layer_get_text, uint32_t layer);
PBW_API(text_layer_set_background_color, uint32_t layer, uint32_t color);
PBW_API(text_layer_set_background_color_2bit, uint32_t layer, uint32_t color);
PBW_API(text_layer_set_text_color, uint32_t layer, uint32_t color);
PBW_API(text_layer_set_text_color_2bit, uint32_t layer, uint32_t color);
PBW_API(text_layer_set_overflow_mode, uint32_t layer, uint32_t line_mode);
PBW_API(text_layer_set_font, uint32_t layer, uint32_t font);
PBW_API(text_layer_set_text_alignment, uint32_t layer, uint32_t text_alignment);
PBW_API(text_layer_enable_screen_text_flow_and_paging, uint32_t layer, uint32_t inset);
PBW_API(text_layer_restore_default_text_flow_and_paging, uint32_t layer);
PBW_API(text_layer_get_content_size, uint32_t layer);
PBW_API(text_layer_set_size, uint32_t layer, uint32_t size);

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

#pragma mark - Standard C / Locale
PBW_API(setlocale, uint32_t category, uint32_t namePtr);

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
PBW_API(strftime, uint32_t s, uint32_t maxsize, uint32_t format, uint32_t tb);

#endif /* api_h */
