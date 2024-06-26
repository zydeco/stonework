//
//  call.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 03/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../cpu/cpu.h"
#import "PBWAddressSpace.h"
#import "PBWRuntime.h"
#import <inttypes.h>
#import "api.h"

struct pbw_api {
    const char *name;
    BOOL returnsWord;
    int8_t numberOfArguments;
    union {
        pbw_api_impl implementation;
        uint32_t returnValue;
    };
};

#define PBW_API_VARARGS -1

void pbw_api_call_impl(pbw_ctx ctx, pbw_api_impl implementation, int8_t numberOfArguments, BOOL returnsWord);

#undef PBW_API
#define GET_PBW_API(_1,_2,_3,_4,NAME,...) NAME
#define PBW_API1(name) {#name, YES, 0, .implementation = (pbw_api_impl)(pbw_api_ ## name)}
#define PBW_API2(name, returnsWord) {#name, returnsWord, 0, .implementation = (pbw_api_impl)(pbw_api_ ## name)}
#define PBW_API3(name, returnsWord, nargs) {#name, returnsWord, nargs, .implementation = (pbw_api_impl)(pbw_api_ ## name)}
#define PBW_API4(name, returnsWord, nargs, implName) {#name, returnsWord, nargs, .implementation = (pbw_api_impl)(pbw_api_ ## implName)}
#define PBW_API(...) GET_PBW_API(__VA_ARGS__, PBW_API4, PBW_API3, PBW_API2, PBW_API1)(__VA_ARGS__)

#define GET_PBW_API_STUB(_1,_2,NAME,...) NAME
#define PBW_API_STUB(...) GET_PBW_API_STUB(__VA_ARGS__, PBW_API_STUB2, PBW_API_STUB1)(__VA_ARGS__)
#define PBW_API_STUB1(name) {#name, NO, -1, .returnValue = 0}
#define PBW_API_STUB2(name, _returnValue) {#name, YES, -1, .returnValue = _returnValue}

#define PBW_API_UNIMPLEMENTED(name, ...) {#name, YES, 0, NULL}

static const struct pbw_api pblApi[] = {
    PBW_API_STUB(accel_data_service_subscribe__deprecated),
    PBW_API_STUB(accel_data_service_unsubscribe),
    PBW_API_STUB(accel_service_peek, 0xffffffff),
    PBW_API_STUB(accel_service_set_samples_per_update),
    PBW_API_STUB(accel_service_set_sampling_rate),
    PBW_API(accel_tap_service_subscribe, NO, 1),
    PBW_API(accel_tap_service_unsubscribe, NO),
    PBW_API_UNIMPLEMENTED(action_bar_layer_legacy2_add_to_window),
    PBW_API_UNIMPLEMENTED(action_bar_layer_legacy2_clear_icon),
    PBW_API_UNIMPLEMENTED(action_bar_layer_legacy2_create),
    PBW_API_UNIMPLEMENTED(action_bar_layer_legacy2_destroy),
    PBW_API_UNIMPLEMENTED(action_bar_layer_legacy2_get_layer),
    PBW_API_UNIMPLEMENTED(action_bar_layer_legacy2_remove_from_window),
    PBW_API_UNIMPLEMENTED(action_bar_layer_legacy2_set_background_color_2bit),
    PBW_API_UNIMPLEMENTED(action_bar_layer_legacy2_set_click_config_provider),
    PBW_API_UNIMPLEMENTED(action_bar_layer_legacy2_set_context),
    PBW_API_UNIMPLEMENTED(action_bar_layer_legacy2_set_icon),
    PBW_API_UNIMPLEMENTED(animation_legacy2_create),
    PBW_API_UNIMPLEMENTED(animation_legacy2_destroy),
    PBW_API_UNIMPLEMENTED(animation_legacy2_get_context),
    PBW_API_UNIMPLEMENTED(animation_legacy2_is_scheduled),
    PBW_API_UNIMPLEMENTED(animation_legacy2_schedule),
    PBW_API_UNIMPLEMENTED(animation_legacy2_set_curve),
    PBW_API_UNIMPLEMENTED(animation_legacy2_set_delay),
    PBW_API_UNIMPLEMENTED(animation_legacy2_set_duration),
    PBW_API_UNIMPLEMENTED(animation_legacy2_set_handlers),
    PBW_API_UNIMPLEMENTED(animation_legacy2_set_implementation),
    PBW_API_UNIMPLEMENTED(animation_legacy2_unschedule),
    PBW_API_UNIMPLEMENTED(animation_legacy2_unschedule_all),
    PBW_API_UNIMPLEMENTED(app_comm_get_sniff_interval),
    PBW_API_UNIMPLEMENTED(app_comm_set_sniff_interval),
    PBW_API(app_event_loop, NO),
    PBW_API_UNIMPLEMENTED(_unknown32),
    PBW_API_UNIMPLEMENTED(_unknown33),
    PBW_API(app_log, NO, 4),
    PBW_API(app_message_deregister_callbacks, NO),
    PBW_API(app_message_open, YES, 2),
    PBW_API_UNIMPLEMENTED(_unknown37),
    PBW_API_UNIMPLEMENTED(_unknown38),
    PBW_API_UNIMPLEMENTED(_unknown39),
    PBW_API_UNIMPLEMENTED(_unknown40),
    PBW_API_UNIMPLEMENTED(_unknown41),
    PBW_API_UNIMPLEMENTED(_unknown42),
    PBW_API_UNIMPLEMENTED(app_sync_deinit),
    PBW_API_UNIMPLEMENTED(app_sync_get),
    PBW_API_STUB(app_sync_init),
    PBW_API_UNIMPLEMENTED(app_sync_set),
    PBW_API(app_timer_cancel, NO, 1),
    PBW_API(app_timer_register, YES, 3),
    PBW_API(app_timer_reschedule, YES, 2),
    PBW_API(atan2_lookup, YES, 2),
    PBW_API_UNIMPLEMENTED(atoi),
    PBW_API_UNIMPLEMENTED(atol),
    PBW_API(battery_state_service_peek),
    PBW_API(battery_state_service_subscribe, YES, 1),
    PBW_API(battery_state_service_unsubscribe, NO),
    PBW_API(bitmap_layer_create, YES, 2),
    PBW_API(bitmap_layer_destroy, NO),
    PBW_API(bitmap_layer_get_layer, YES, 1),
    PBW_API(bitmap_layer_set_alignment, NO, 2),
    PBW_API(bitmap_layer_set_background_color_2bit, NO, 2),
    PBW_API(bitmap_layer_set_bitmap, NO, 2),
    PBW_API(bitmap_layer_set_compositing_mode, NO, 2),
    PBW_API(bluetooth_connection_service_peek),
    PBW_API(bluetooth_connection_service_subscribe, NO, 1),
    PBW_API(bluetooth_connection_service_unsubscribe, NO),
    PBW_API_UNIMPLEMENTED(click_number_of_clicks_counted),
    PBW_API_UNIMPLEMENTED(click_recognizer_get_button_id),
    PBW_API(clock_copy_time_string, NO, 2),
    PBW_API(clock_is_24h_style),
    PBW_API(cos_lookup, YES, 1),
    PBW_API_UNIMPLEMENTED(data_logging_create),
    PBW_API_UNIMPLEMENTED(data_logging_finish),
    PBW_API_UNIMPLEMENTED(data_logging_log),
    PBW_API_UNIMPLEMENTED(dict_calc_buffer_size),
    PBW_API_UNIMPLEMENTED(dict_calc_buffer_size_from_tuplets),
    PBW_API_UNIMPLEMENTED(dict_find),
    PBW_API_UNIMPLEMENTED(dict_merge),
    PBW_API_UNIMPLEMENTED(dict_read_begin_from_buffer),
    PBW_API_UNIMPLEMENTED(dict_read_first),
    PBW_API_UNIMPLEMENTED(dict_read_next),
    PBW_API_UNIMPLEMENTED(dict_serialize_tuplets),
    PBW_API_UNIMPLEMENTED(dict_serialize_tuplets_to_buffer__deprecated),
    PBW_API_UNIMPLEMENTED(dict_serialize_tuplets_to_buffer_with_iter),
    PBW_API_UNIMPLEMENTED(dict_write_begin),
    PBW_API_UNIMPLEMENTED(dict_write_cstring),
    PBW_API_UNIMPLEMENTED(dict_write_data),
    PBW_API_UNIMPLEMENTED(dict_write_end),
    PBW_API_UNIMPLEMENTED(dict_write_int),
    PBW_API_UNIMPLEMENTED(dict_write_int16),
    PBW_API_UNIMPLEMENTED(dict_write_int32),
    PBW_API_UNIMPLEMENTED(dict_write_int8),
    PBW_API_UNIMPLEMENTED(dict_write_tuplet),
    PBW_API_UNIMPLEMENTED(dict_write_uint16),
    PBW_API_UNIMPLEMENTED(dict_write_uint32),
    PBW_API_UNIMPLEMENTED(dict_write_uint8),
    PBW_API(fonts_get_system_font, YES, 1),
    PBW_API(fonts_load_custom_font, YES, 1),
    PBW_API(fonts_unload_custom_font, NO, 1),
    PBW_API(free, NO, 1),
    PBW_API(gbitmap_create_as_sub_bitmap, YES, 2),
    PBW_API(gbitmap_create_with_data, YES, 1),
    PBW_API(gbitmap_create_with_resource, YES, 1),
    PBW_API(gbitmap_destroy, NO, 1),
    PBW_API(gmtime, YES, 1),
    PBW_API(gpath_create, YES, 1),
    PBW_API(gpath_destroy, NO, 1),
    PBW_API(gpath_draw_filled_legacy, NO, 2),
    PBW_API(gpath_draw_outline, NO, 2),
    PBW_API(gpath_move_to, NO, 2),
    PBW_API(gpath_rotate_to, NO, 2),
    PBW_API(gpoint_equal, YES, 2),
    PBW_API(graphics_context_set_compositing_mode, NO, 2),
    PBW_API(graphics_context_set_fill_color_2bit, NO, 2),
    PBW_API(graphics_context_set_stroke_color_2bit, NO, 2),
    PBW_API(graphics_context_set_text_color_2bit, NO, 2),
    PBW_API(graphics_draw_bitmap_in_rect, NO, 4),
    PBW_API(graphics_draw_circle, NO, 3),
    PBW_API(graphics_draw_line, NO, 3),
    PBW_API(graphics_draw_pixel, NO, 2),
    PBW_API(graphics_draw_rect, NO, 3),
    PBW_API_UNIMPLEMENTED(graphics_draw_round_rect, NO, 4),
    PBW_API(graphics_fill_circle, NO, 3),
    PBW_API(graphics_fill_rect, NO, 4),
    PBW_API_UNIMPLEMENTED(_unknown124),
    PBW_API_UNIMPLEMENTED(graphics_text_layout_get_max_used_size),
    PBW_API(grect_align, NO, 4),
    PBW_API(grect_center_point, YES, 1),
    PBW_API(grect_clip, YES, 2),
    PBW_API(grect_contains_point, YES, 2),
    PBW_API(grect_crop, NO, 4),
    PBW_API(grect_equal, YES, 2),
    PBW_API(grect_is_empty, YES, 1),
    PBW_API(grect_standardize, NO, 1),
    PBW_API(gsize_equal, YES, 2),
    PBW_API_UNIMPLEMENTED(inverter_layer_create),
    PBW_API_UNIMPLEMENTED(inverter_layer_destroy),
    PBW_API_UNIMPLEMENTED(inverter_layer_get_layer),
    PBW_API(layer_add_child, NO, 2),
    PBW_API(layer_create, YES, 2),
    PBW_API(layer_create_with_data, YES, 3),
    PBW_API(layer_destroy, NO, 1),
    PBW_API(layer_get_bounds, NO, 2),
    PBW_API(layer_get_clips, YES, 1),
    PBW_API(layer_get_data, YES, 1),
    PBW_API(layer_get_frame, NO, 2),
    PBW_API(layer_get_hidden, YES, 1),
    PBW_API(layer_get_window, YES, 1),
    PBW_API(layer_insert_above_sibling, NO, 2),
    PBW_API(layer_insert_below_sibling, NO, 2),
    PBW_API(layer_mark_dirty, NO, 1),
    PBW_API(layer_remove_child_layers, NO, 1),
    PBW_API(layer_remove_from_parent, NO, 1),
    PBW_API(layer_set_bounds, NO, 3),
    PBW_API(layer_set_clips, NO, 2),
    PBW_API(layer_set_frame, NO, 3),
    PBW_API(layer_set_hidden, NO, 2),
    PBW_API(layer_set_update_proc, NO, 2),
    PBW_API_UNIMPLEMENTED(light_enable),
    PBW_API_UNIMPLEMENTED(light_enable_interaction),
    PBW_API(localtime__deprecated, YES, 1),
    PBW_API(malloc, YES, 1),
    PBW_API(memcpy, YES, 3),
    PBW_API(memmove, YES, 3),
    PBW_API(memset, YES, 3),
    PBW_API_UNIMPLEMENTED(menu_cell_basic_draw),
    PBW_API_UNIMPLEMENTED(menu_cell_basic_header_draw),
    PBW_API_UNIMPLEMENTED(menu_cell_title_draw),
    PBW_API_UNIMPLEMENTED(menu_index_compare),
    PBW_API_UNIMPLEMENTED(menu_layer_legacy2_create),
    PBW_API_UNIMPLEMENTED(menu_layer_destroy),
    PBW_API_UNIMPLEMENTED(menu_layer_get_layer),
    PBW_API_UNIMPLEMENTED(menu_layer_get_scroll_layer),
    PBW_API_UNIMPLEMENTED(menu_layer_get_selected_index),
    PBW_API_UNIMPLEMENTED(menu_layer_reload_data),
    PBW_API_UNIMPLEMENTED(menu_layer_legacy2_set_callbacks__deprecated),
    PBW_API_UNIMPLEMENTED(menu_layer_set_click_config_onto_window),
    PBW_API_UNIMPLEMENTED(menu_layer_set_selected_index),
    PBW_API_UNIMPLEMENTED(menu_layer_set_selected_next),
    PBW_API_UNIMPLEMENTED(number_window_create),
    PBW_API_UNIMPLEMENTED(number_window_destroy),
    PBW_API_UNIMPLEMENTED(number_window_get_value),
    PBW_API_UNIMPLEMENTED(number_window_set_label),
    PBW_API_UNIMPLEMENTED(number_window_set_max),
    PBW_API_UNIMPLEMENTED(number_window_set_min),
    PBW_API_UNIMPLEMENTED(number_window_set_step_size),
    PBW_API_UNIMPLEMENTED(number_window_set_value),
    PBW_API(persist_delete, YES, 1),
    PBW_API(persist_exists, YES, 1),
    PBW_API(persist_get_size, YES, 1),
    PBW_API(persist_read_bool, YES, 1),
    PBW_API_UNIMPLEMENTED(persist_read_data__deprecated),
    PBW_API(persist_read_int, YES, 1),
    PBW_API_UNIMPLEMENTED(persist_read_string__deprecated),
    PBW_API(persist_write_bool, YES, 2),
    PBW_API_UNIMPLEMENTED(persist_write_data__deprecated),
    PBW_API(persist_write_int, YES, 2),
    PBW_API(persist_write_string, YES, 2),
    PBW_API_UNIMPLEMENTED(property_animation_legacy2_create),
    PBW_API_UNIMPLEMENTED(property_animation_legacy2_create_layer_frame),
    PBW_API_UNIMPLEMENTED(property_animation_legacy2_destroy),
    PBW_API_UNIMPLEMENTED(property_animation_legacy2_update_gpoint),
    PBW_API_UNIMPLEMENTED(property_animation_legacy2_update_grect),
    PBW_API_UNIMPLEMENTED(property_animation_legacy2_update_int16),
    PBW_API(psleep, NO, 1),
    PBW_API(rand, YES, 0),
    PBW_API(resource_get_handle, YES, 1),
    PBW_API(resource_load, YES, 3),
    PBW_API(resource_load_byte_range, YES, 4),
    PBW_API(resource_size, YES, 1),
    PBW_API_UNIMPLEMENTED(rot_bitmap_layer_create),
    PBW_API_UNIMPLEMENTED(rot_bitmap_layer_destroy),
    PBW_API_UNIMPLEMENTED(rot_bitmap_layer_increment_angle),
    PBW_API_UNIMPLEMENTED(rot_bitmap_layer_set_angle),
    PBW_API_UNIMPLEMENTED(rot_bitmap_layer_set_corner_clip_color_2bit),
    PBW_API_UNIMPLEMENTED(rot_bitmap_set_compositing_mode),
    PBW_API_UNIMPLEMENTED(rot_bitmap_set_src_ic),
    PBW_API_UNIMPLEMENTED(scroll_layer_add_child),
    PBW_API_UNIMPLEMENTED(scroll_layer_create),
    PBW_API_UNIMPLEMENTED(scroll_layer_destroy),
    PBW_API_UNIMPLEMENTED(scroll_layer_get_content_offset),
    PBW_API_UNIMPLEMENTED(scroll_layer_get_content_size),
    PBW_API_UNIMPLEMENTED(scroll_layer_get_layer),
    PBW_API_UNIMPLEMENTED(scroll_layer_get_shadow_hidden),
    PBW_API_UNIMPLEMENTED(scroll_layer_scroll_down_click_handler),
    PBW_API_UNIMPLEMENTED(scroll_layer_scroll_up_click_handler),
    PBW_API_UNIMPLEMENTED(scroll_layer_set_callbacks),
    PBW_API_UNIMPLEMENTED(scroll_layer_set_click_config_onto_window),
    PBW_API_UNIMPLEMENTED(scroll_layer_set_content_offset),
    PBW_API_UNIMPLEMENTED(scroll_layer_set_content_size),
    PBW_API_UNIMPLEMENTED(scroll_layer_set_context),
    PBW_API_UNIMPLEMENTED(scroll_layer_set_frame),
    PBW_API_UNIMPLEMENTED(scroll_layer_set_shadow_hidden),
    PBW_API_UNIMPLEMENTED(simple_menu_layer_create),
    PBW_API_UNIMPLEMENTED(simple_menu_layer_destroy),
    PBW_API_UNIMPLEMENTED(simple_menu_layer_get_layer),
    PBW_API_UNIMPLEMENTED(simple_menu_layer_get_selected_index),
    PBW_API_UNIMPLEMENTED(simple_menu_layer_set_selected_index),
    PBW_API(sin_lookup, YES, 1),
    PBW_API(snprintf, YES, 3),
    PBW_API(srand, NO, 0),
    PBW_API(strcat, YES, 2),
    PBW_API(strcmp, YES, 2),
    PBW_API(strcpy, YES, 2),
    PBW_API(strftime, YES, 4),
    PBW_API(strlen, YES, 1),
    PBW_API(strncat, YES, 3),
    PBW_API(strncmp, YES, 3),
    PBW_API(strncpy, YES, 3),
    PBW_API(text_layer_legacy2_create, YES, 2, text_layer_create),
    PBW_API(text_layer_legacy2_destroy, NO, 1, text_layer_destroy),
    PBW_API(text_layer_legacy2_get_content_size, YES, 1, text_layer_get_content_size),
    PBW_API(text_layer_legacy2_get_layer, YES, 1, text_layer_get_layer),
    PBW_API(text_layer_legacy2_get_text, YES, 1, text_layer_get_text),
    PBW_API(text_layer_legacy2_set_background_color_2bit, NO, 2, text_layer_set_background_color_2bit),
    PBW_API(text_layer_legacy2_set_font, NO, 2, text_layer_set_font),
    PBW_API(text_layer_legacy2_set_overflow_mode, NO, 2, text_layer_set_overflow_mode),
    PBW_API(text_layer_legacy2_set_size, NO, 2, text_layer_set_size),
    PBW_API(text_layer_legacy2_set_text, NO, 2, text_layer_set_text),
    PBW_API(text_layer_legacy2_set_text_alignment, NO, 2, text_layer_set_text_alignment),
    PBW_API(text_layer_legacy2_set_text_color_2bit, NO, 2, text_layer_set_text_color_2bit),
    PBW_API_UNIMPLEMENTED(_unknown261),
    PBW_API(tick_timer_service_subscribe, NO, 2),
    PBW_API(tick_timer_service_unsubscribe, NO),
    PBW_API(time__deprecated, YES, 1),
    PBW_API_UNIMPLEMENTED(time_ms_deprecated),
    PBW_API_UNIMPLEMENTED(vibes_cancel),
    PBW_API_UNIMPLEMENTED(vibes_double_pulse),
    PBW_API_UNIMPLEMENTED(vibes_enqueue_custom_pattern),
    PBW_API_UNIMPLEMENTED(vibes_long_pulse),
    PBW_API_UNIMPLEMENTED(vibes_short_pulse),
    PBW_API(window_create),
    PBW_API(window_destroy, NO, 1),
    PBW_API(window_get_click_config_provider, YES, 1),
    PBW_API_UNIMPLEMENTED(window_get_fullscreen),
    PBW_API(window_get_root_layer, YES, 1),
    PBW_API(window_is_loaded, YES, 1),
    PBW_API(window_set_background_color_2bit, NO, 2),
    PBW_API(window_set_click_config_provider, NO, 2),
    PBW_API(window_set_click_config_provider_with_context, NO, 3),
    PBW_API_UNIMPLEMENTED(window_set_fullscreen),
    PBW_API_UNIMPLEMENTED(window_set_status_bar_icon),
    PBW_API(window_set_window_handlers, NO, 1),
    PBW_API(window_stack_contains_window, YES, 1),
    PBW_API(window_stack_get_top_window),
    PBW_API(window_stack_pop, YES, 1),
    PBW_API(window_stack_pop_all, NO, 1),
    PBW_API(window_stack_push, NO, 2),
    PBW_API(window_stack_remove, YES, 2),
    PBW_API_UNIMPLEMENTED(app_focus_service_subscribe),
    PBW_API_UNIMPLEMENTED(app_focus_service_unsubscribe),
    PBW_API(window_get_user_data, YES, 1),
    PBW_API(window_set_user_data, NO, 2),
    PBW_API(app_message_get_context),
    PBW_API(app_message_inbox_size_maximum),
    PBW_API(app_message_outbox_begin, YES, 1),
    PBW_API(app_message_outbox_send),
    PBW_API(app_message_outbox_size_maximum),
    PBW_API(app_message_register_inbox_dropped, YES, 1),
    PBW_API(app_message_register_inbox_received, YES, 1),
    PBW_API(app_message_register_outbox_failed, YES, 1),
    PBW_API(app_message_register_outbox_sent, YES, 1),
    PBW_API(app_message_set_context, YES, 1),
    PBW_API_UNIMPLEMENTED(window_long_click_subscribe),
    PBW_API_UNIMPLEMENTED(window_multi_click_subscribe),
    PBW_API_UNIMPLEMENTED(window_raw_click_subscribe),
    PBW_API_UNIMPLEMENTED(window_set_click_context),
    PBW_API_UNIMPLEMENTED(window_single_click_subscribe),
    PBW_API_UNIMPLEMENTED(window_single_repeating_click_subscribe),
    PBW_API(graphics_draw_text, NO, 4),
    PBW_API_UNIMPLEMENTED(dict_serialize_tuplets_to_buffer),
    PBW_API(persist_read_data, YES, 1),
    PBW_API(persist_read_string, YES, 1),
    PBW_API(persist_write_data, YES, 3),
    PBW_API_UNIMPLEMENTED(dict_size),
    PBW_API_UNIMPLEMENTED(graphics_text_layout_get_content_size),
    PBW_API_UNIMPLEMENTED(simple_menu_layer_get_menu_layer),
    PBW_API_STUB(accel_data_service_subscribe),
    PBW_API(calloc, YES, 2),
    PBW_API_UNIMPLEMENTED(bitmap_layer_get_bitmap),
    PBW_API_UNIMPLEMENTED(menu_layer_legacy2_set_callbacks),
    PBW_API(window_get_click_config_context, YES, 1),
    PBW_API_UNIMPLEMENTED(number_window_get_window),
    PBW_API(realloc, YES, 2),
    PBW_API(gbitmap_create_blank_2bit, YES, 2),
    PBW_API_UNIMPLEMENTED(click_recognizer_is_repeating),
    PBW_API_STUB(accel_raw_data_service_subscribe),
    PBW_API_UNIMPLEMENTED(app_worker_is_running),
    PBW_API_UNIMPLEMENTED(app_worker_kill),
    PBW_API_UNIMPLEMENTED(app_worker_launch),
    PBW_API_UNIMPLEMENTED(app_worker_message_subscribe),
    PBW_API_UNIMPLEMENTED(app_worker_message_unsubscribe),
    PBW_API_UNIMPLEMENTED(app_worker_send_message),
    PBW_API_UNIMPLEMENTED(worker_event_loop),
    PBW_API_UNIMPLEMENTED(worker_launch_app),
    PBW_API_UNIMPLEMENTED(heap_bytes_free),
    PBW_API_UNIMPLEMENTED(heap_bytes_used),
    PBW_API_UNIMPLEMENTED(compass_service_peek),
    PBW_API_UNIMPLEMENTED(compass_service_set_heading_filter),
    PBW_API_UNIMPLEMENTED(compass_service_subscribe),
    PBW_API_UNIMPLEMENTED(compass_service_unsubscribe),
    PBW_API_UNIMPLEMENTED(uuid_equal),
    PBW_API_UNIMPLEMENTED(uuid_to_string),
    PBW_API(gpath_draw_filled, NO, 2),
    PBW_API_UNIMPLEMENTED(animation_legacy2_set_custom_curve),
    PBW_API_UNIMPLEMENTED(watch_info_get_color),
    PBW_API_UNIMPLEMENTED(watch_info_get_firmware_version),
    PBW_API_UNIMPLEMENTED(watch_info_get_model),
    PBW_API_UNIMPLEMENTED(graphics_capture_frame_buffer_2bit),
    PBW_API_UNIMPLEMENTED(graphics_frame_buffer_is_captured),
    PBW_API_UNIMPLEMENTED(graphics_release_frame_buffer),
    PBW_API(clock_to_timestamp, YES, 3),
    PBW_API_UNIMPLEMENTED(launch_reason),
    PBW_API_UNIMPLEMENTED(wakeup_cancel),
    PBW_API_UNIMPLEMENTED(wakeup_cancel_all),
    PBW_API_UNIMPLEMENTED(wakeup_get_launch_event),
    PBW_API_UNIMPLEMENTED(wakeup_query),
    PBW_API_UNIMPLEMENTED(wakeup_schedule),
    PBW_API_UNIMPLEMENTED(wakeup_service_subscribe),
    PBW_API(clock_is_timezone_set),
    PBW_API_UNIMPLEMENTED(i18n_get_system_locale),
    PBW_API_UNIMPLEMENTED(_localeconv_r),
    PBW_API(setlocale, YES, 2),
    PBW_API(mktime, YES, 1),
    PBW_API_UNIMPLEMENTED(gcolor_equal__deprecated), // gcolor_equal on aplite
    PBW_API_UNIMPLEMENTED(__profiler_init),
    PBW_API_UNIMPLEMENTED(__profiler_print_stats),
    PBW_API_UNIMPLEMENTED(__profiler_start),
    PBW_API_UNIMPLEMENTED(__profiler_stop),
    PBW_API_UNIMPLEMENTED(_unknown369),
    PBW_API(bitmap_layer_set_background_color, NO, 2),
    PBW_API(graphics_context_set_fill_color, NO, 2),
    PBW_API(graphics_context_set_stroke_color, NO, 2),
    PBW_API(graphics_context_set_text_color, NO, 2),
    PBW_API_UNIMPLEMENTED(rot_bitmap_layer_set_corner_clip_color),
    PBW_API_UNIMPLEMENTED(_unknown375),
    PBW_API_UNIMPLEMENTED(_unknown376),
    PBW_API(window_set_background_color, NO, 2),
    PBW_API(clock_get_timezone, NO, 2),
    PBW_API(localtime, YES, 1),
    PBW_API_UNIMPLEMENTED(animation_create),
    PBW_API_UNIMPLEMENTED(animation_destroy),
    PBW_API_UNIMPLEMENTED(animation_get_context),
    PBW_API_UNIMPLEMENTED(animation_is_scheduled),
    PBW_API_UNIMPLEMENTED(animation_schedule),
    PBW_API_UNIMPLEMENTED(animation_set_curve),
    PBW_API_UNIMPLEMENTED(animation_set_custom_curve),
    PBW_API_UNIMPLEMENTED(animation_set_delay),
    PBW_API_UNIMPLEMENTED(animation_set_duration),
    PBW_API_UNIMPLEMENTED(animation_set_handlers),
    PBW_API_UNIMPLEMENTED(animation_set_implementation),
    PBW_API_UNIMPLEMENTED(animation_unschedule),
    PBW_API_UNIMPLEMENTED(animation_unschedule_all),
    PBW_API(gbitmap_create_blank, YES, 4),
    PBW_API_UNIMPLEMENTED(graphics_capture_frame_buffer),
    PBW_API_UNIMPLEMENTED(graphics_capture_frame_buffer_format),
    PBW_API_UNIMPLEMENTED(property_animation_create),
    PBW_API_UNIMPLEMENTED(property_animation_create_layer_frame),
    PBW_API_UNIMPLEMENTED(property_animation_destroy),
    PBW_API_UNIMPLEMENTED(property_animation_from),
    PBW_API_UNIMPLEMENTED(property_animation_get_animation),
    PBW_API_UNIMPLEMENTED(property_animation_subject),
    PBW_API_UNIMPLEMENTED(property_animation_to),
    PBW_API_UNIMPLEMENTED(property_animation_update_gpoint),
    PBW_API_UNIMPLEMENTED(property_animation_update_grect),
    PBW_API_UNIMPLEMENTED(property_animation_update_int16),
    PBW_API(gbitmap_create_blank_with_palette, YES, 4),
    PBW_API(gbitmap_get_bounds, NO, 2),
    PBW_API(gbitmap_get_bytes_per_row, YES, 1),
    PBW_API(gbitmap_get_data, YES, 1),
    PBW_API(gbitmap_get_format, YES, 1),
    PBW_API(gbitmap_get_palette, YES, 1),
    PBW_API(gbitmap_set_bounds, NO, 3),
    PBW_API(gbitmap_set_data, NO, 4),
    PBW_API(gbitmap_set_palette, NO, 3),
    PBW_API_UNIMPLEMENTED(gbitmap_sequence_create_with_resource),
    PBW_API_UNIMPLEMENTED(gbitmap_sequence_destroy),
    PBW_API_UNIMPLEMENTED(gbitmap_sequence_get_bitmap_size),
    PBW_API_UNIMPLEMENTED(gbitmap_sequence_get_current_frame_idx),
    PBW_API_UNIMPLEMENTED(gbitmap_sequence_get_total_num_frames),
    PBW_API_UNIMPLEMENTED(gbitmap_sequence_update_bitmap_next_frame),
    PBW_API(gbitmap_create_from_png_data, YES, 2),
    PBW_API_UNIMPLEMENTED(animation_clone),
    PBW_API_UNIMPLEMENTED(animation_get_delay),
    PBW_API_UNIMPLEMENTED(animation_get_duration),
    PBW_API_UNIMPLEMENTED(animation_get_play_count),
    PBW_API_UNIMPLEMENTED(animation_get_elapsed),
    PBW_API_UNIMPLEMENTED(animation_get_reverse),
    PBW_API_UNIMPLEMENTED(animation_sequence_create),
    PBW_API_UNIMPLEMENTED(animation_sequence_create_from_array),
    PBW_API_UNIMPLEMENTED(animation_set_play_count),
    PBW_API_UNIMPLEMENTED(animation_set_elapsed),
    PBW_API_UNIMPLEMENTED(animation_set_reverse),
    PBW_API_UNIMPLEMENTED(animation_spawn_create),
    PBW_API_UNIMPLEMENTED(animation_spawn_create_from_array),
    PBW_API_UNIMPLEMENTED(animation_get_curve),
    PBW_API_UNIMPLEMENTED(animation_get_custom_curve),
    PBW_API_UNIMPLEMENTED(animation_get_implementation),
    PBW_API_UNIMPLEMENTED(launch_get_args),
    PBW_API_UNIMPLEMENTED(menu_layer_create),
    PBW_API_UNIMPLEMENTED(_unknown440),
    PBW_API_UNIMPLEMENTED(gbitmap_sequence_get_play_count),
    PBW_API_UNIMPLEMENTED(gbitmap_sequence_restart),
    PBW_API_UNIMPLEMENTED(gbitmap_sequence_set_play_count),
    PBW_API(graphics_context_set_antialiased, NO, 2),
    PBW_API(graphics_context_set_stroke_width, NO, 2),
    PBW_API_UNIMPLEMENTED(action_bar_layer_add_to_window),
    PBW_API_UNIMPLEMENTED(action_bar_layer_clear_icon),
    PBW_API_UNIMPLEMENTED(action_bar_layer_create),
    PBW_API_UNIMPLEMENTED(action_bar_layer_destroy),
    PBW_API_UNIMPLEMENTED(action_bar_layer_get_layer),
    PBW_API_UNIMPLEMENTED(action_bar_layer_remove_from_window),
    PBW_API_UNIMPLEMENTED(action_bar_layer_set_background_color),
    PBW_API_UNIMPLEMENTED(action_bar_layer_set_click_config_provider),
    PBW_API_UNIMPLEMENTED(action_bar_layer_set_context),
    PBW_API_UNIMPLEMENTED(action_bar_layer_set_icon),
    PBW_API_UNIMPLEMENTED(action_bar_layer_set_icon_animated),
    PBW_API_UNIMPLEMENTED(gbitmap_sequence_update_bitmap_by_elapsed),
    PBW_API(gbitmap_create_palettized_from_1bit, YES, 1),
    PBW_API_UNIMPLEMENTED(menu_cell_layer_is_highlighted),
    PBW_API_UNIMPLEMENTED(graphics_draw_rotated_bitmap),
    PBW_API_UNIMPLEMENTED(action_bar_layer_set_icon_press_animation),
    PBW_API(text_layer_create, YES, 2),
    PBW_API(text_layer_destroy, NO, 1),
    PBW_API(text_layer_get_content_size, YES, 1),
    PBW_API(text_layer_get_layer, YES, 1),
    PBW_API(text_layer_get_text, YES, 1),
    PBW_API(text_layer_set_background_color, NO, 2),
    PBW_API(text_layer_set_font, NO, 2),
    PBW_API(text_layer_set_overflow_mode, NO, 2),
    PBW_API(text_layer_set_size, NO, 2),
    PBW_API(text_layer_set_text, NO, 2),
    PBW_API(text_layer_set_text_alignment, NO, 2),
    PBW_API(text_layer_set_text_color, NO, 2),
    PBW_API_UNIMPLEMENTED(gdraw_command_draw),
    PBW_API_UNIMPLEMENTED(gdraw_command_frame_draw),
    PBW_API_UNIMPLEMENTED(gdraw_command_frame_get_duration),
    PBW_API_UNIMPLEMENTED(gdraw_command_frame_set_duration),
    PBW_API_UNIMPLEMENTED(gdraw_command_get_fill_color),
    PBW_API_UNIMPLEMENTED(gdraw_command_get_hidden),
    PBW_API_UNIMPLEMENTED(gdraw_command_get_num_points),
    PBW_API_UNIMPLEMENTED(gdraw_command_get_path_open),
    PBW_API_UNIMPLEMENTED(gdraw_command_get_point),
    PBW_API_UNIMPLEMENTED(gdraw_command_get_radius),
    PBW_API_UNIMPLEMENTED(gdraw_command_get_stroke_color),
    PBW_API_UNIMPLEMENTED(gdraw_command_get_stroke_width),
    PBW_API_UNIMPLEMENTED(gdraw_command_get_type),
    PBW_API_UNIMPLEMENTED(gdraw_command_image_clone),
    PBW_API_UNIMPLEMENTED(gdraw_command_image_create_with_resource),
    PBW_API_UNIMPLEMENTED(gdraw_command_image_destroy),
    PBW_API_UNIMPLEMENTED(gdraw_command_image_draw),
    PBW_API_UNIMPLEMENTED(gdraw_command_image_get_bounds_size),
    PBW_API_UNIMPLEMENTED(gdraw_command_image_get_command_list),
    PBW_API_UNIMPLEMENTED(gdraw_command_image_set_bounds_size),
    PBW_API_UNIMPLEMENTED(gdraw_command_list_draw),
    PBW_API_UNIMPLEMENTED(gdraw_command_list_get_command),
    PBW_API_UNIMPLEMENTED(gdraw_command_list_get_num_commands),
    PBW_API_UNIMPLEMENTED(gdraw_command_list_iterate),
    PBW_API_UNIMPLEMENTED(gdraw_command_sequence_clone),
    PBW_API_UNIMPLEMENTED(gdraw_command_sequence_create_with_resource),
    PBW_API_UNIMPLEMENTED(gdraw_command_sequence_destroy),
    PBW_API_UNIMPLEMENTED(gdraw_command_sequence_get_bounds_size),
    PBW_API_UNIMPLEMENTED(gdraw_command_sequence_get_frame_by_elapsed),
    PBW_API_UNIMPLEMENTED(gdraw_command_sequence_get_frame_by_index),
    PBW_API_UNIMPLEMENTED(gdraw_command_sequence_get_num_frames),
    PBW_API_UNIMPLEMENTED(gdraw_command_sequence_get_play_count),
    PBW_API_UNIMPLEMENTED(gdraw_command_sequence_get_total_duration),
    PBW_API_UNIMPLEMENTED(gdraw_command_sequence_set_bounds_size),
    PBW_API_UNIMPLEMENTED(gdraw_command_sequence_set_play_count),
    PBW_API_UNIMPLEMENTED(gdraw_command_set_fill_color),
    PBW_API_UNIMPLEMENTED(gdraw_command_set_hidden),
    PBW_API_UNIMPLEMENTED(gdraw_command_set_path_open),
    PBW_API_UNIMPLEMENTED(gdraw_command_set_point),
    PBW_API_UNIMPLEMENTED(gdraw_command_set_radius),
    PBW_API_UNIMPLEMENTED(gdraw_command_set_stroke_color),
    PBW_API_UNIMPLEMENTED(gdraw_command_set_stroke_width),
    PBW_API_UNIMPLEMENTED(property_animation_create_bounds_origin),
    PBW_API_UNIMPLEMENTED(property_animation_update_uint32),
    PBW_API(gpath_draw_outline_open, NO, 2),
    PBW_API(time, YES, 1),
    PBW_API_UNIMPLEMENTED(menu_layer_set_highlight_colors),
    PBW_API_UNIMPLEMENTED(menu_layer_set_normal_colors),
    PBW_API_UNIMPLEMENTED(menu_layer_set_callbacks),
    PBW_API_UNIMPLEMENTED(menu_layer_pad_bottom_enable),
    PBW_API_UNIMPLEMENTED(status_bar_layer_create),
    PBW_API_UNIMPLEMENTED(status_bar_layer_destroy),
    PBW_API_UNIMPLEMENTED(status_bar_layer_get_background_color),
    PBW_API_UNIMPLEMENTED(status_bar_layer_get_foreground_color),
    PBW_API_UNIMPLEMENTED(status_bar_layer_get_layer),
    PBW_API_UNIMPLEMENTED(status_bar_layer_set_colors),
    PBW_API_UNIMPLEMENTED(status_bar_layer_set_separator_mode),
    PBW_API_UNIMPLEMENTED(difftime),
    PBW_API(time_ms, YES, 2),
    PBW_API(gcolor_legible_over, YES, 1),
    PBW_API_UNIMPLEMENTED(property_animation_update_gcolor8),
    PBW_API_UNIMPLEMENTED(app_focus_service_subscribe_handlers),
    PBW_API_UNIMPLEMENTED(action_menu_close),
    PBW_API_UNIMPLEMENTED(action_menu_freeze),
    PBW_API_UNIMPLEMENTED(action_menu_get_context),
    PBW_API_UNIMPLEMENTED(action_menu_get_root_level),
    PBW_API_UNIMPLEMENTED(action_menu_hierarchy_destroy),
    PBW_API_UNIMPLEMENTED(action_menu_item_get_action_data),
    PBW_API_UNIMPLEMENTED(action_menu_item_get_label),
    PBW_API_UNIMPLEMENTED(action_menu_level_add_action),
    PBW_API_UNIMPLEMENTED(action_menu_level_add_child),
    PBW_API_UNIMPLEMENTED(action_menu_level_create),
    PBW_API_UNIMPLEMENTED(action_menu_level_set_display_mode),
    PBW_API_UNIMPLEMENTED(action_menu_open),
    PBW_API_UNIMPLEMENTED(action_menu_set_result_window),
    PBW_API_UNIMPLEMENTED(action_menu_unfreeze),
    PBW_API_STUB(dictation_session_create, 0),
    PBW_API_UNIMPLEMENTED(dictation_session_destroy),
    PBW_API_UNIMPLEMENTED(dictation_session_enable_confirmation),
    PBW_API_UNIMPLEMENTED(dictation_session_start),
    PBW_API_UNIMPLEMENTED(dictation_session_stop),
    PBW_API_UNIMPLEMENTED(smartstrap_attribute_begin_write),
    PBW_API_UNIMPLEMENTED(smartstrap_attribute_create),
    PBW_API_UNIMPLEMENTED(smartstrap_attribute_destroy),
    PBW_API_UNIMPLEMENTED(smartstrap_attribute_end_write),
    PBW_API_UNIMPLEMENTED(smartstrap_attribute_get_attribute_id),
    PBW_API_UNIMPLEMENTED(smartstrap_attribute_get_service_id),
    PBW_API_UNIMPLEMENTED(smartstrap_attribute_read),
    PBW_API_UNIMPLEMENTED(smartstrap_service_is_available),
    PBW_API_UNIMPLEMENTED(smartstrap_set_timeout),
    PBW_API_UNIMPLEMENTED(smartstrap_subscribe),
    PBW_API_UNIMPLEMENTED(smartstrap_unsubscribe),
    PBW_API(connection_service_peek_pebble_app_connection),
    PBW_API(connection_service_peek_pebblekit_connection),
    PBW_API(connection_service_subscribe, NO, 2),
    PBW_API(connection_service_unsubscribe, NO),
    PBW_API_UNIMPLEMENTED(dictation_session_enable_error_dialogs),
    PBW_API(gbitmap_get_data_row_info, NO, 3),
    PBW_API_UNIMPLEMENTED(content_indicator_configure_direction),
    PBW_API_UNIMPLEMENTED(content_indicator_create),
    PBW_API_UNIMPLEMENTED(content_indicator_destroy),
    PBW_API_UNIMPLEMENTED(content_indicator_get_content_available),
    PBW_API_UNIMPLEMENTED(content_indicator_set_content_available),
    PBW_API_UNIMPLEMENTED(scroll_layer_get_content_indicator),
    PBW_API_UNIMPLEMENTED(menu_layer_get_center_focused),
    PBW_API_UNIMPLEMENTED(menu_layer_set_center_focused),
    PBW_API(grect_inset, NO, 3),
    PBW_API_UNIMPLEMENTED(gpoint_from_polar, YES, 4),
    PBW_API_UNIMPLEMENTED(graphics_draw_arc, NO, 4),
    PBW_API_UNIMPLEMENTED(graphics_fill_radial, NO, 4),
    PBW_API_UNIMPLEMENTED(grect_centered_from_polar, NO, 4),
    PBW_API_UNIMPLEMENTED(graphics_text_attributes_create),
    PBW_API_UNIMPLEMENTED(graphics_text_attributes_destroy),
    PBW_API_UNIMPLEMENTED(graphics_text_attributes_enable_paging),
    PBW_API_UNIMPLEMENTED(graphics_text_attributes_enable_screen_text_flow),
    PBW_API_UNIMPLEMENTED(graphics_text_attributes_restore_default_paging),
    PBW_API_UNIMPLEMENTED(graphics_text_attributes_restore_default_text_flow),
    PBW_API_UNIMPLEMENTED(graphics_text_layout_get_content_size_with_attributes),
    PBW_API(layer_convert_point_to_screen, YES, 2),
    PBW_API(layer_convert_rect_to_screen, NO, 4),
    PBW_API_UNIMPLEMENTED(scroll_layer_get_paging),
    PBW_API_UNIMPLEMENTED(scroll_layer_set_paging),
    PBW_API(text_layer_enable_screen_text_flow_and_paging, NO, 2),
    PBW_API(text_layer_restore_default_text_flow_and_paging, NO, 1),
    PBW_API_UNIMPLEMENTED(menu_layer_is_index_selected),
    PBW_API_UNIMPLEMENTED(health_service_activities_iterate),
    PBW_API_UNIMPLEMENTED(health_service_any_activity_accessible),
    PBW_API_STUB(health_service_events_subscribe),
    PBW_API_UNIMPLEMENTED(health_service_events_unsubscribe),
    PBW_API_UNIMPLEMENTED(health_service_get_minute_history),
    PBW_API_STUB(health_service_metric_accessible, 0),
    PBW_API_UNIMPLEMENTED(health_service_peek_current_activities),
    PBW_API_UNIMPLEMENTED(health_service_sum),
    PBW_API_UNIMPLEMENTED(health_service_sum_today),
    PBW_API(time_start_of_today),
    PBW_API_UNIMPLEMENTED(health_service_metric_averaged_accessible),
    PBW_API_UNIMPLEMENTED(health_service_sum_averaged),
    PBW_API_UNIMPLEMENTED(health_service_get_measurement_system_for_display),
    PBW_API_UNIMPLEMENTED(gdraw_command_frame_get_command_list),
    // basalt, chalk, diorite, emery
    PBW_API(gcolor_equal, YES, 2),
    PBW_API_UNIMPLEMENTED(app_glance_add_slice),
    PBW_API_UNIMPLEMENTED(app_glance_reload),
    PBW_API_UNIMPLEMENTED(exit_reason_set),
    PBW_API_UNIMPLEMENTED(health_service_aggregate_averaged),
    PBW_API_UNIMPLEMENTED(health_service_cancel_metric_alert),
    PBW_API_UNIMPLEMENTED(health_service_metric_aggregate_averaged_accessible),
    PBW_API_UNIMPLEMENTED(health_service_peek_current_value),
    PBW_API_UNIMPLEMENTED(health_service_register_metric_alert),
    PBW_API(layer_get_unobstructed_bounds, NO, 2),
    PBW_API_UNIMPLEMENTED(preferred_result_display_duration),
    PBW_API_STUB(unobstructed_area_service_subscribe),
    PBW_API_STUB(unobstructed_area_service_unsubscribe),
    PBW_API_UNIMPLEMENTED(memory_cache_flush),
    PBW_API_UNIMPLEMENTED(rocky_event_loop_with_resource),
    PBW_API_UNIMPLEMENTED(health_service_get_heart_rate_sample_period_expiration_sec),
    PBW_API_UNIMPLEMENTED(health_service_set_heart_rate_sample_period),
    PBW_API_UNIMPLEMENTED(preferred_content_size),
    PBW_API_UNIMPLEMENTED(quiet_time_is_active)
};

#define kNumberOfAPICalls (sizeof(pblApi) / sizeof(pblApi[0]))

uint32_t pbw_api_call(pbw_cpu cpu, void *userData, uint32_t addr, pbw_mem_op op, pbw_mem_size size, uint32_t value) {
    PBWRuntime *runtime = (__bridge id)(userData);
    int apiNum = addr/4;
    if (apiNum == kJumpTableEntries - 1) {
        pbw_cpu_stop(cpu, PBW_ERR_OK);
        return 0;
    } else if (apiNum < kNumberOfAPICalls) {
        const struct pbw_api api = pblApi[apiNum];
        if (api.numberOfArguments == -1) {
            // API stub
            NSLog(@"API stub: %s", api.name);
            if (api.returnsWord) pbw_cpu_reg_set(cpu, 0, api.returnValue);
        } else if (api.implementation == NULL) {
            // API not implemented
            NSLog(@"API call not implemented: %s", api.name);
            pbw_cpu_stop(cpu, PBW_ERR_NOT_IMPLEMENTED);
        } else {
            //NSLog(@"API call: %s", api.name);
            pbw_api_call_impl(runtime.runtimeContext, api.implementation, api.numberOfArguments, api.returnsWord);
        }
    }
    
    // return address in link register
    pbw_cpu_reg_set(cpu, REG_PC, pbw_cpu_reg_get(cpu, REG_LR));
    return 0;
}

// return pointer from emulated pointer
void* pbw_ctx_get_pointer(pbw_ctx ctx, uint32_t ptr) {
    if (ptr >= ctx->ramBase && ptr < (ctx->ramBase + ctx->ramSize)) {
        // pointer in RAM region
        return ctx->ramSlice + (ptr - ctx->ramBase);
    } else if (ptr >= ctx->appBase && ptr < (ctx->appBase + ctx->appSize)) {
        // pointer in app region
        return ctx->appSlice + (ptr - ctx->appBase);
    } else {
        // pointer shouldn't be anywhere else
        return NULL;
    }
}

// convert pointer to emulated pointer
uint32_t pbw_ctx_make_pointer(pbw_ctx ctx, void *ptr) {
    if (ptr >= ctx->ramSlice && ptr < (ctx->ramSlice + ctx->ramSize)) {
        return ctx->ramBase + (uint32_t)(ptr - ctx->ramSlice);
    } else if (ptr >= ctx->appSlice && ptr < (ctx->appSlice + ctx->appSize)) {
        return ctx->appBase + (uint32_t)(ptr - ctx->appSlice);
    } else {
        // pointer shouldn't be anywhere else
        return 0;
    }
}

void pbw_api_call_impl(pbw_ctx ctx, pbw_api_impl implementation, int8_t numberOfArguments, BOOL returnsWord) {
    uint32_t result = 0;
    pbw_cpu cpu = ctx->cpu;
    if (numberOfArguments <= 4) {
        // arguments are in r0, r1, r2, r3
        result = implementation(ctx, pbw_cpu_reg_get(cpu, 0), pbw_cpu_reg_get(cpu, 1), pbw_cpu_reg_get(cpu, 2), pbw_cpu_reg_get(cpu, 3));
    } else {
        // first 4 arguments are in r0, r1, r2, r3
        // next are in stack, in reverse order
        // implementation should handle this and be defined to accept 4 arguments
        pbw_cpu_stop(cpu, PBW_ERR_NOT_IMPLEMENTED);
        return;
    }
    if (returnsWord) {
        pbw_cpu_reg_set(cpu, 0, result);
    }
}
