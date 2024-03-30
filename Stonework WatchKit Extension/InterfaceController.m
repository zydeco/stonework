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
-(NSString*)timeText;
-(id)sharedPUICApplication;
-(void)_setStatusBarTimeHidden:(BOOL)hidden animated:(BOOL)animated completion:(void (^)(void))completion;
-(BOOL)prefersStatusBarHidden;
@end

@interface InterfaceController ()

@end

@implementation InterfaceController
{
    PBWRuntime *runtime;
}

+ (void)load {
    /* Hack to make the digital time overlay disappear (on watchOS 6) */
    Class CLKTimeFormatter = NSClassFromString(@"CLKTimeFormatter");
    if ([CLKTimeFormatter instancesRespondToSelector:@selector(timeText)]) {
        Method m = class_getInstanceMethod(CLKTimeFormatter, @selector(timeText));
        method_setImplementation(m, imp_implementationWithBlock(^NSString*(id self, SEL _cmd) { return @" "; }));
    }
    /* hide status bar on watchOS 10 */
    Class clsUIViewController = NSClassFromString(@"UIViewController");
    if ([clsUIViewController instancesRespondToSelector:@selector(prefersStatusBarHidden)]) {
        Method m = class_getInstanceMethod(clsUIViewController, @selector(prefersStatusBarHidden));
        method_setImplementation(m, imp_implementationWithBlock(^BOOL(id self, SEL _cmd) { return YES; }));
    }
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
}

- (void)hideTimeLabel {
    /* Hack to make the digital time overlay disappear (on watchOS 5) */
    id fullScreenView = [self fullScreenView];
    if ([fullScreenView respondsToSelector:@selector(timeLabel)]) {
        [[[fullScreenView timeLabel] layer] setOpacity:0];
    }
    /* Hack to make the digital time overlay disappear (on watchOS 7) */
    Class PUICApplication = NSClassFromString(@"PUICApplication");
    if ([PUICApplication instancesRespondToSelector:@selector(_setStatusBarTimeHidden:animated:completion:)]) {
        [[PUICApplication sharedApplication] _setStatusBarTimeHidden:YES animated:NO completion:nil];
    }

}

- (id)fullScreenView {
    id parentView = [[[[[[NSClassFromString(@"UIApplication") sharedApplication] keyWindow] rootViewController] viewControllers] firstObject] view];
    id view = [self findDescendantViewOfClass:NSClassFromString(@"SPFullScreenView") inView:parentView]; // watchOS 5
    if (view == nil) {
        view = [self findDescendantViewOfClass:NSClassFromString(@"SPInterfaceRemoteView") inView:parentView]; // watchOS 6
    }
    return view;
}

- (id)findDescendantViewOfClass:(Class)viewClass inView:(id)parentView {
    for (NSObject *view in [parentView subviews]) {
        if ([view isKindOfClass:viewClass]) {
            return view;
        } else {
            id foundView = [self findDescendantViewOfClass:viewClass inView:view];
            if (foundView != nil) return foundView;
        }
    }
    return nil;
}

- (void)didAppear {
    [self hideTimeLabel];
    if (runtime == nil) {
        [self loadWatchface];
    }
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
    [runtime performSelector:@selector(run) withObject:nil afterDelay:0.0];
    
    // add screen view
    id<PBWScreenView> screenView = runtime.screenView;
    id fullScreenView = [self fullScreenView];
    [fullScreenView addSubview:screenView];
    CGRect bounds = [fullScreenView bounds];
    screenView.center = CGPointMake(bounds.size.width / 2.0, bounds.size.height / 2.0);
}

- (void)willActivate {
    if ([WKExtension sharedExtension].applicationState == WKApplicationStateActive) {
        [runtime resume];
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    [runtime pause];
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
