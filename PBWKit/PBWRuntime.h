//
//  PBWRuntime.h
//  Stonework WatchKit Extension
//
//  Created by Jesús A. Álvarez on 14/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <xlocale.h>
#import "api/api.h"
#import "PBWScreenView.h"

@class PBWApp, PBWObject, PBWGraphicsContext, PBWWindow, PBWFont;

NS_ASSUME_NONNULL_BEGIN

@interface PBWRuntime : NSObject
{
    uint32_t _batteryServiceHandler;
}

@property (nonatomic, readonly) PBWApp *app;
@property (nonatomic, readonly) pbw_ctx runtimeContext;
@property (nonatomic, readonly) BOOL running;
@property (nonatomic) locale_t locale;

- (instancetype)initWithApp:(PBWApp*)app;
- (BOOL)run;
- (void)stop;
- (void)startEventLoop;
- (void)tick:(nullable NSTimer *)timer;

// Graphics
@property (nonatomic, readonly) CGSize screenSize;
@property (nonatomic, readonly) NSObject<PBWScreenView> *screenView;
@property (nonatomic, readonly) PBWGraphicsContext *graphicsContext;
@property (nonatomic, readonly) NSMutableArray<PBWWindow*> *windowStack;

// OS Objects
@property (nonatomic, readonly) NSMutableDictionary<NSNumber*,__kindof PBWObject*> *objects;
- (uint32_t)addObject:(PBWObject*)obj;
- (nullable NSData*)systemResourceWithKey:(NSString*)key;
- (PBWFont*)systemFontWithKey:(NSString*)key;

// Persistent Storage
@property (nonatomic, readonly) NSMutableDictionary<NSNumber*,NSObject*> *persistentStorage;
- (void)savePersistentStorage;

// Battery Service
@property (nonatomic, readonly) uint32_t batteryChargeState;
@property (nonatomic, assign) uint32_t batteryServiceHandler;

// Connection Service
@property (nonatomic, assign) uint32_t connPebbleKitHandler;
@property (nonatomic, assign) uint32_t connAppHandler;
@property (nonatomic, assign) uint32_t connBluetoothHandler;

// Tick Timer Service
- (void)startTickTimerWithUnits:(TimeUnits)timeUnits handler:(uint32_t)handler;

// AppMessage
@property (nonatomic, assign) uint32_t appMessageContext;
@property (nonatomic, assign) uint32_t appMessageInboxReceivedCallback;
@property (nonatomic, assign) uint32_t appMessageInboxDroppedCallback;
@property (nonatomic, assign) uint32_t appMessageOutboxSentCallback;
@property (nonatomic, assign) uint32_t appMessageOutboxFailedCallback;

@end

NS_ASSUME_NONNULL_END
