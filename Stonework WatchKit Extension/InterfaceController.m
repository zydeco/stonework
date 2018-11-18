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

    // Configure interface objects here.
}

- (void)didAppear {
    /* Hack to make the digital time overlay disappear */
    NSArray *views = [[[[[[[NSClassFromString(@"UIApplication") sharedApplication] keyWindow] rootViewController] viewControllers] firstObject] view] subviews];
    id fullScreenView = nil;
    for (NSObject *view in views) {
        if ([view isKindOfClass:NSClassFromString(@"SPFullScreenView")]) {
            fullScreenView = view;
            break;
        }
    }
    [[[fullScreenView timeLabel] layer] setOpacity:0];
    
    // run pebble watchface
    NSString *appName = [NSProcessInfo processInfo].environment[@"PBWAppBundle"] ?: @"hello-pebble";
    PBWBundle *bundle = [PBWBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:appName withExtension:@"pbw" subdirectory:@"Faces"]];
    PBWApp *app = [[PBWApp alloc] initWithBundle:bundle platform:PBWPlatformTypeAplite];
    runtime = [[PBWRuntime alloc] initWithApp:app];
    [runtime run];
    
    // add screen view
    id<PBWScreenView> screenView = runtime.screenView;
    [fullScreenView addSubview:screenView];
    CGRect bounds = [fullScreenView bounds];
    screenView.center = CGPointMake(bounds.size.width / 2.0, bounds.size.height / 2.0);
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end
