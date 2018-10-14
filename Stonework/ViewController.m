//
//  ViewController.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 14/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "ViewController.h"
#import "PBWBundle.h"
#import "PBWApp.h"
#import "PBWRuntime.h"

@interface ViewController ()

@end

@implementation ViewController
{
    PBWRuntime *rt;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self loadPebbleApp];
}

- (void)loadPebbleApp {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *appName = [defaults stringForKey:@"PBWAppBundle"] ?: @"roman_digital_20";
    PBWBundle *pbw = [PBWBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:appName withExtension:@"pbw" subdirectory:@"Faces"]];
    NSLog(@"pbw %@", pbw);
    PBWPlatformType platform = PBWPlatformTypeFromString([defaults stringForKey:@"PBWPlatform"] ?: @"basalt");
    PBWApp *app = [[PBWApp alloc] initWithBundle:pbw platform:platform];
    if (app == nil) {
        app = [[PBWApp alloc] initWithBundle:pbw platform:PBWPlatformTypeAplite];
    }
    NSLog(@"app %@", app);
    rt = [[PBWRuntime alloc] initWithApp:app];
    [self.screenView addSubview:(UIView*)rt.screenView];
    [rt run];
    //printf("%s\n", [rt disassemble].UTF8String);
}

@end
