//
//  app_message.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 11/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../../cpu/cpu.h"
#import "../api.h"
#import "PBWRuntime.h"

typedef enum {
    //! (0) All good, operation was successful.
    APP_MSG_OK = 0,
    //! (2) The other end did not confirm receiving the sent data with an (n)ack in time.
    APP_MSG_SEND_TIMEOUT = 1 << 1,
    //! (4) The other end rejected the sent data, with a "nack" reply.
    APP_MSG_SEND_REJECTED = 1 << 2,
    //! (8) The other end was not connected.
    APP_MSG_NOT_CONNECTED = 1 << 3,
    //! (16) The local application was not running.
    APP_MSG_APP_NOT_RUNNING = 1 << 4,
    //! (32) The function was called with invalid arguments.
    APP_MSG_INVALID_ARGS = 1 << 5,
    //! (64) There are pending (in or outbound) messages that need to be processed first before
    //! new ones can be received or sent.
    APP_MSG_BUSY = 1 << 6,
    //! (128) The buffer was too small to contain the incoming message.
    APP_MSG_BUFFER_OVERFLOW = 1 << 7,
    //! (512) The resource had already been released.
    APP_MSG_ALREADY_RELEASED = 1 << 9,
    //! (1024) The callback was already registered.
    APP_MSG_CALLBACK_ALREADY_REGISTERED = 1 << 10,
    //! (2048) The callback could not be deregistered, because it had not been registered before.
    APP_MSG_CALLBACK_NOT_REGISTERED = 1 << 11,
    //! (4096) The system did not have sufficient application memory to
    //! perform the requested operation.
    APP_MSG_OUT_OF_MEMORY = 1 << 12,
    //! (8192) App message was closed.
    APP_MSG_CLOSED = 1 << 13,
    //! (16384) An internal OS error prevented AppMessage from completing an operation.
    APP_MSG_INTERNAL_ERROR = 1 << 14,
    //! (32768) The function was called while App Message was not in the appropriate state.
    APP_MSG_INVALID_STATE = 1 << 15,
} AppMessageResult;

uint32_t pbw_api_app_message_open(pbw_ctx ctx, uint32_t size_inbound, uint32_t size_outbound) {
    return APP_MSG_OUT_OF_MEMORY;
}

uint32_t pbw_api_app_message_deregister_callbacks(pbw_ctx ctx) {
    PBWRuntime *runtime = ctx->runtime;
    runtime.appMessageContext = 0;
    runtime.appMessageInboxReceivedCallback = 0;
    runtime.appMessageInboxDroppedCallback = 0;
    runtime.appMessageOutboxSentCallback = 0;
    runtime.appMessageOutboxFailedCallback = 0;
    return 0;
}

uint32_t pbw_api_app_message_get_context(pbw_ctx ctx) {
    return ctx->runtime.appMessageContext;
}

uint32_t pbw_api_app_message_set_context(pbw_ctx ctx, uint32_t context) {
    uint32_t previousContext = ctx->runtime.appMessageContext;
    ctx->runtime.appMessageContext = context;
    return previousContext;
}

uint32_t pbw_api_app_message_register_inbox_received(pbw_ctx ctx, uint32_t callback) {
    uint32_t previousCallback = ctx->runtime.appMessageInboxReceivedCallback;
    ctx->runtime.appMessageInboxReceivedCallback = callback;
    return previousCallback;
}

uint32_t pbw_api_app_message_register_inbox_dropped(pbw_ctx ctx, uint32_t callback) {
    uint32_t previousCallback = ctx->runtime.appMessageInboxDroppedCallback;
    ctx->runtime.appMessageInboxDroppedCallback = callback;
    return previousCallback;
}

uint32_t pbw_api_app_message_register_outbox_sent(pbw_ctx ctx, uint32_t callback) {
    uint32_t previousCallback = ctx->runtime.appMessageOutboxSentCallback;
    ctx->runtime.appMessageOutboxSentCallback = callback;
    return previousCallback;
}

uint32_t pbw_api_app_message_register_outbox_failed(pbw_ctx ctx, uint32_t callback) {
    uint32_t previousCallback = ctx->runtime.appMessageOutboxFailedCallback;
    ctx->runtime.appMessageOutboxFailedCallback = callback;
    return previousCallback;
}

uint32_t pbw_api_app_message_inbox_size_maximum(pbw_ctx ctx) {
    return 0;
}

uint32_t pbw_api_app_message_outbox_size_maximum(pbw_ctx ctx) {
    return 0;
}

uint32_t pbw_api_app_message_outbox_begin(pbw_ctx ctx, uint32_t iterator) {
    return APP_MSG_INTERNAL_ERROR;
}

uint32_t pbw_api_app_message_outbox_send(pbw_ctx ctx) {
    return APP_MSG_INTERNAL_ERROR;
}
