//
//  InterfaceController.m
//  Stonework WatchKit Extension
//
//  Created by Jesús A. Álvarez on 14/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "InterfaceController.h"
#import "PBWKit.h"

@import ObjectiveC.runtime;
@import WatchConnectivity;

@interface NSObject (fs_override)
+(id)sharedApplication;
-(id)keyWindow;
-(id)rootViewController;
-(NSArray *)viewControllers;
-(id)view;
-(NSArray *)subviews;
-(id)timeLabel;
-(id)layer;
-(void)addSubview:(id)subview;
-(CGPoint)center;
@end

@interface InterfaceController ()

@end

@implementation InterfaceController
{
    PBWRuntime *runtime;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
}

- (void)hideTimeLabel {
    /* Hack to make the digital time overlay disappear */
    id fullScreenView = [self fullScreenView];
    [[[fullScreenView timeLabel] layer] setOpacity:0];
}

- (id)fullScreenView {
    NSArray *views = [[[[[[[NSClassFromString(@"UIApplication") sharedApplication] keyWindow] rootViewController] viewControllers] firstObject] view] subviews];
    for (NSObject *view in views) {
        if ([view isKindOfClass:NSClassFromString(@"SPFullScreenView")]) {
            return view;
        }
    }
    return nil;
}

- (void)didAppear {
    [self hideTimeLabel];
    [self loadWatchface];
}

- (void)loadWatchface {
    if (runtime) {
        [runtime stop];
        [runtime.screenView removeFromSuperview];
        runtime = nil;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *documentsURL = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
    NSURL *watchfaceURL = [documentsURL URLByAppendingPathComponent:@"watchface.pbw" isDirectory:NO];
    PBWBundle *bundle = [PBWBundle bundleWithURL:watchfaceURL];
    if (bundle == nil) return;
    PBWApp *app = [[PBWApp alloc] initWithBundle:bundle platform:PBWPlatformTypeBasalt];
    if (app == nil) app = [[PBWApp alloc] initWithBundle:bundle platform:PBWPlatformTypeAplite];
    if (app == nil) return;
    runtime = [[PBWRuntime alloc] initWithApp:app];
    [runtime run];
    
    // add screen view
    id<PBWScreenView> screenView = runtime.screenView;
    id fullScreenView = [self fullScreenView];
    [fullScreenView addSubview:screenView];
    CGRect bounds = [fullScreenView bounds];
    screenView.center = CGPointMake(bounds.size.width / 2.0, bounds.size.height / 2.0);
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    if (runtime.running) {
        [runtime tick:nil];
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (void)sessionReachabilityDidChange:(WCSession *)session {
    uint32_t connected = session.activationState == WCSessionActivationStateActivated && session.reachable;
    if (runtime.running) {
        pbw_ctx ctx = runtime.runtimeContext;
        if (runtime.connAppHandler) {
            pbw_cpu_call(ctx->cpu, runtime.connAppHandler, NULL, 1, connected);
        }
        if (runtime.connPebbleKitHandler) {
            pbw_cpu_call(ctx->cpu, runtime.connPebbleKitHandler, NULL, 1, connected);
        };
        if (runtime.connBluetoothHandler) {
            pbw_cpu_call(ctx->cpu, runtime.connBluetoothHandler, NULL, 1, connected);
        };
    }
}

@end
