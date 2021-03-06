//
//  PBWRuntime.m
//  Stonework WatchKit Extension
//
//  Created by Jesús A. Álvarez on 14/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWRuntime.h"
#import "PBWApp.h"
#import "PBWBundle.h"
#import "PBWManager.h"
#import "cpu.h"
#import "weemalloc.h"
#import "api/api.h"
#import "PBWAddressSpace.h"
#import "PBWGraphicsContext.h"
#import "PBWWindow.h"
#import "PBWFont.h"
#import "PBWAddressSpace+Globals.h"

@import ObjectiveC.runtime;
@import UIKit;

uint32_t pbw_api_setlocale(pbw_ctx ctx, uint32_t category, uint32_t namePtr) {
    const char *name = pbw_ctx_get_pointer(ctx, namePtr);
    int mask = category ? (1 << category) : LC_ALL_MASK;
    ctx->runtime.locale = newlocale(mask, name, LC_GLOBAL_LOCALE);
    return kPBWGlobalLocale;
}

static Class PBWScreenView = nil;
static void * PBWScreenViewRuntimeKey = &PBWScreenViewRuntimeKey;

static void PBWScreenView_drawRect(NSObject<PBWScreenView> *self, SEL _cmd, CGRect rect) {
    PBWRuntime *runtime = objc_getAssociatedObject(self, PBWScreenViewRuntimeKey);
    [runtime drawScreenViewWithContext:UIGraphicsGetCurrentContext()];
}

void PBWRunTick(pbw_ctx ctx, struct tm *host_tm, TimeUnits unitsChanged, uint32_t handler);

@implementation PBWRuntime
{
    struct pbw_ctx ctx;
    uint32_t entryPoint;
    uint8_t *jumpTableSlice;
    uint32_t nextObject;
    NSTimer *tickTimer;
    uint32_t tickSerivceHandler;
    struct tm lastTickServiceTime;
    time_t lastTime;
    NSMutableDictionary<NSString*,PBWFont*> *systemFonts;
    NSMutableArray<PBWWindow*> *windowStack;
}

+ (void)load {
    Class UIViewClass = NSClassFromString(@"UIView");
    PBWScreenView = objc_allocateClassPair(UIViewClass, "PBWScreenView", 0);
    SEL drawRectSelector = NSSelectorFromString(@"drawRect:");
    Method UIViewDrawRect = class_getInstanceMethod(UIViewClass, drawRectSelector);
    class_addMethod(PBWScreenView, drawRectSelector, (IMP)PBWScreenView_drawRect, method_getTypeEncoding(UIViewDrawRect));
    objc_registerClassPair(PBWScreenView);
}

- (instancetype)initWithApp:(PBWApp *)app {
    if (self = [super init]) {
        _app = app;
        if (app.platform == PBWPlatformTypeChalk) {
            _screenSize = CGSizeMake(180, 180);
        } else {
            _screenSize = CGSizeMake(144, 168);
        }
        // screen should exist before running!
        _screenView = [[PBWScreenView alloc] initWithFrame:CGRectMake(0, 0, _screenSize.width, _screenSize.height)];
        objc_setAssociatedObject(_screenView, PBWScreenViewRuntimeKey, self, OBJC_ASSOCIATION_ASSIGN);
    }
    return self;
}

- (void)initializeEmulator {
    ctx.cpu = pbw_cpu_init(NULL, NULL, (__bridge void *)(self));
    
    // map app image
    NSData *appImage = _app.appBinary;
    if (appImage.length > kAppMaxSize) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"App image too big" userInfo:@{@"appSize": @(appImage.length), @"maxSize": @(kAppMaxSize)}];
    }
    ctx.appBase = kAppBase;
    uint32_t virtualSize = _app.virtualSize;
    if (_app.virtualSize == _app.loadSize) {
        // add more scratch space? probably not needed
        virtualSize += 1024;
    }
    uint32_t appSize = pad4K(virtualSize);
    ctx.appSlice = calloc(1, appSize);
    ctx.appSize = appSize;
    uint32_t loadSize = _app.loadSize;
    memcpy(ctx.appSlice, appImage.bytes, loadSize);
    entryPoint = kAppBase + _app.entryPoint;
    pbw_cpu_mem_map_ptr(ctx.cpu, ctx.appBase, appSize, PBW_MEM_RWX, ctx.appSlice);
    
    // apply relocation table
    uint32_t relocTableOffset = _app.relocTableOffset;
    uint32_t numRelocEntries = _app.numRelocEntries;
    for (int i=0; i < numRelocEntries; i++) {
        uint32_t relocOffset = OSReadLittleInt32(appImage.bytes, relocTableOffset + (4*i));
        uint32_t relocValue = OSReadLittleInt32(ctx.appSlice, relocOffset);
        OSWriteLittleInt32(ctx.appSlice, relocOffset, relocValue + ctx.appBase);
    }
    
    // API jump table
    jumpTableSlice = calloc(1, kJumpTableSize);
    for (int i=0; i < kJumpTableEntries; i++) {
        OSWriteLittleInt32(jumpTableSlice, 4*i, kAPIBase + 4*i);
    }
    pbw_cpu_mem_map_ptr(ctx.cpu, kJumpTableBase, kJumpTableSize, PBW_MEM_RWX, jumpTableSlice);
    uint32_t symbolTableOffset = _app.symbolTableOffset;
    OSWriteLittleInt32(ctx.appSlice, symbolTableOffset, kJumpTableBase);
    pbw_cpu_hook_exec(ctx.cpu, kAPIBase, kJumpTableSize, pbw_api_call, (__bridge void*)self);
    
    // map memory for stack and heap
    ctx.ramSize = kRAMSize;
    ctx.ramBase = kRAMBase;
    ctx.ramSlice = calloc(1, ctx.ramSize);
    ctx.heapPtr = ctx.ramSlice + kRAMGlobalsSize;
    weemalloc_init(ctx.heapPtr, kHeapSize);
    pbw_cpu_mem_map_ptr(ctx.cpu, ctx.ramBase, ctx.ramSize, PBW_MEM_RWX, ctx.ramSlice);
    
    ctx.runtime = self;
    _objects = [NSMutableDictionary dictionaryWithCapacity:32];
    nextObject = kOSObjectTagBase;
    
    // persistent storage
    NSString *persistKey = [NSString stringWithFormat:@"PersistentStorage-%@-%@", _app.UUID.UUIDString, NSStringFromPBWPlatformType(_app.platform)];
    NSDictionary *persistentStorage = [[PBWManager defaultManager].sharedUserDefaults objectForKey:persistKey];
    if (persistentStorage == nil) {
        _persistentStorage = [NSMutableDictionary dictionaryWithCapacity:0];
    } else {
        _persistentStorage = persistentStorage.mutableCopy;
    }
    
    // system resources
    systemFonts = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // base graphics context
    _graphicsContext = [[PBWGraphicsContext alloc] initWithRuntime:self];
    windowStack = [NSMutableArray arrayWithCapacity:1];
    
    // locale
    self.locale = newlocale(LC_ALL_MASK, [NSLocale currentLocale].localeIdentifier.UTF8String, LC_GLOBAL_LOCALE);
}

- (void)setLocale:(locale_t)locale {
    if (_locale && _locale != LC_GLOBAL_LOCALE) {
        freelocale(_locale);
    }
    _locale = locale;
    const char *localeName = querylocale(LC_TIME_MASK, _locale);
    pbw_cpu_mem_write_block(ctx.cpu, kPBWGlobalLocale, 1+strlen(localeName), localeName);
}

- (void)deinitializeEmulator {
    free(ctx.appSlice);
    free(ctx.ramSlice);
    free(jumpTableSlice);
    pbw_cpu_destroy(ctx.cpu);
}

- (void)dealloc {
    [self deinitializeEmulator];
}

- (BOOL)run {
    NSAssert(!_running, @"Runtime already running!");
    @try {
        [self initializeEmulator];
        
        pbw_cpu_reg_set(ctx.cpu, REG_SP, kStackTop);
        pbw_cpu_reg_set(ctx.cpu, REG_PC, entryPoint);
        pbw_cpu_reg_set(ctx.cpu, REG_LR, kAPIBase + kJumpTableSize - 4); // called when main() exits
        _running = YES;
        pbw_err err = pbw_cpu_resume(ctx.cpu);
        if (err) {
            _running = NO;
            NSLog(@"pbw_cpu_resume: %u", err);
        }
        return YES;
    } @catch (NSException *exception) {
        return NO;
    }
}

- (void)pause {
    if (!_running) return;
    NSLog(@"Runtime pausing");
    _running = NO;
    [self stopTimers];
}

- (void)resume {
    if (_running) return;
    NSLog(@"Runtime resuming");
    _running = YES;
    [self resumeTimers];
    [self startEventLoop];
}

- (void)stop {
    if (!_running) return;
    _running = NO;
    [self stopTimers];
}

- (void)stopTimers {
    [tickTimer invalidate];
}

- (void)resumeTimers {
    if (tickSerivceHandler) {
        [self startTickTimerWithUnits:_tickServiceUnits handler:tickSerivceHandler];
    }
}

- (time_t)guestTime {
    return _timeOverride ? _timeOverride.timeIntervalSince1970 : time(NULL);
}

- (void)savePersistentStorage {
    NSString *persistKey = [NSString stringWithFormat:@"PersistentStorage-%@-%@", _app.UUID.UUIDString, NSStringFromPBWPlatformType(_app.platform)];
    [[NSUserDefaults standardUserDefaults] setObject:_persistentStorage forKey:persistKey];
}

- (void)startEventLoop {
    [_screenView setNeedsDisplay];
}

- (void)startTickTimerWithUnits:(TimeUnits)timeUnits handler:(uint32_t)handler {
    _tickServiceUnits = timeUnits;
    tickSerivceHandler = handler;
    if (handler == 0) {
        [tickTimer invalidate];
        tickTimer = nil;
        return;
    }
    
    time_t now = self.guestTime;
    localtime_r(&now, &lastTickServiceTime);
    NSTimeInterval thisTick = floor([NSDate timeIntervalSinceReferenceDate]);
    NSDate *nextFireDate = [NSDate dateWithTimeIntervalSinceReferenceDate:thisTick + 1.05];
    tickTimer = [[NSTimer alloc] initWithFireDate:nextFireDate interval:1.0 target:self selector:@selector(tick:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:tickTimer forMode:NSRunLoopCommonModes];
    lastTime = 0;
    [self tick:nil];
}

- (void)tick {
    [self tick:nil];
}

- (void)tick:(NSTimer *)timer {
    struct tm thisTick;
    time_t now = self.guestTime;
    
    if ((timer == nil || now != lastTime) && tickSerivceHandler) {
        localtime_r(&now, &thisTick);
        TimeUnits changedUnits = 0;
        if (thisTick.tm_sec != lastTickServiceTime.tm_sec) changedUnits |= SECOND_UNIT;
        if (thisTick.tm_min != lastTickServiceTime.tm_min) changedUnits |= MINUTE_UNIT;
        if (thisTick.tm_hour != lastTickServiceTime.tm_hour) changedUnits |= HOUR_UNIT;
        if (thisTick.tm_mday != lastTickServiceTime.tm_mday) changedUnits |= DAY_UNIT;
        if (thisTick.tm_mon != lastTickServiceTime.tm_mon) changedUnits |= MONTH_UNIT;
        if (thisTick.tm_year != lastTickServiceTime.tm_year) changedUnits |= YEAR_UNIT;
        lastTickServiceTime = thisTick;
        if (lastTime == 0 || timer == nil || changedUnits & _tickServiceUnits) {
            PBWRunTick(&ctx, &lastTickServiceTime, changedUnits, tickSerivceHandler);
        }
        lastTime = now;
    }
}

- (void)drawScreenViewWithContext:(CGContextRef)context {
    PBWWindow *topWindow = self.topWindow;
    if (topWindow) {
        if (_running) {
            [_graphicsContext drawWindow:topWindow];
        }
        if (_screenView && context) {
            CGImageRef image = CGBitmapContextCreateImage(_graphicsContext->cgContext);
            CGContextDrawImage(context, _screenView.bounds, image);
            CGImageRelease(image);
        }
        topWindow->dirty = NO;
    }
}

- (id)screenImage {
    CGImageRef cgImage = CGBitmapContextCreateImage(_graphicsContext->cgContext);
    UIImage *screenImage = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationDownMirrored];
    CGImageRelease(cgImage);
    return screenImage;
}

# pragma mark - Accessors

- (struct pbw_ctx *)runtimeContext {
    return &ctx;
}

- (uint32_t)addObject:(PBWObject *)obj {
    nextObject += 4;
    _objects[@(nextObject)] = obj;
    return nextObject;
}

#pragma mark - System Resources

- (nullable NSData*)systemResourceWithKey:(NSString*)key {
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    if ([key hasPrefix:@"FONT_KEY_"]) {
        // font
        NSString *resourceName = [[key substringFromIndex:9].lowercaseString stringByReplacingOccurrencesOfString:@"gothic" withString:@"renaissance"];
        NSString *resourcePath = [bundle pathForResource:resourceName ofType:@"pbf"];
        return resourcePath ? [NSData dataWithContentsOfFile:resourcePath] : nil;
    }
    return nil;
}

- (PBWFont *)systemFontWithKey:(NSString *)key {
    PBWFont *font = systemFonts[key];
    if (font) return font;
    font = [[PBWFont alloc] initWithRuntime:self fontKey:key];
    if (font) {
        systemFonts[key] = font;
        return font;
    } else {
        // fallback font
        return [self systemFontWithKey:@"FONT_KEY_RENAISSANCE_09"];
    }
}

#pragma mark - Accelerometer Service

- (void)tap {
    if (_running && _accelTapServiceHandler) {
        // simulate +1 tap in Z axis
        pbw_cpu_call(ctx.cpu, _accelTapServiceHandler, NULL, 2, 2, 1);
    }
}

#pragma mark - Battery State Service

- (void)batteryLevelOrStateDidChange:(NSNotification *)notification {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:_cmd withObject:notification waitUntilDone:NO];
        return;
    }
    if (_running && _batteryServiceHandler) {
        pbw_cpu_call(ctx.cpu, _batteryServiceHandler, NULL, 1, self.batteryChargeState);
    }
}

#pragma mark - Window Stack

- (void)pushWindow:(PBWWindow*)window animated:(BOOL)animated {
    if (window == nil) return;
    PBWWindow *previousTopWindow = self.topWindow;
    [windowStack addObject:window];
    if (window.loaded) {
        [window didAppear];
    } else {
        [window didLoad];
    }
    if (previousTopWindow) {
        [previousTopWindow didDisappear];
    }
    [window markDirty];
    [_screenView setNeedsDisplay];
}

- (nullable PBWWindow*)popWindow:(BOOL)animated {
    PBWWindow *window = self.topWindow;
    if (window) {
        [windowStack removeLastObject];
        [window didDisappear];
        [self.topWindow markDirty];
        [self.topWindow didAppear];
    }
    [_screenView setNeedsDisplay];
    return window;
}

- (void)popAllWindows:(BOOL)animated {
    [windowStack makeObjectsPerformSelector:@selector(didDisappear)];
    [windowStack removeAllObjects];
    [_screenView setNeedsDisplay];
}

- (BOOL)removeWindow:(PBWWindow*)window animated:(BOOL)animated {
    if (window == nil) {
        return NO;
    } else if (self.topWindow == window) {
        [self popWindow:animated];
        return YES;
    } else if ([self containsWindow:window]) {
        [windowStack removeObject:window];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)containsWindow:(PBWWindow*)window {
    return window ? [windowStack containsObject:window] : NO;
}

- (nullable PBWWindow*)topWindow {
    return windowStack.lastObject;
}

@end

uint32_t pbw_api_app_event_loop(pbw_ctx ctx) {
    pbw_cpu_stop(ctx->cpu, PBW_ERR_OK);
    [ctx->runtime startEventLoop];
    return 0;
}
