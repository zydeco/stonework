//
//  AppDelegate.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 14/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "AppDelegate.h"
#import "PBWKit.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

+ (instancetype)sharedInstance {
    return (AppDelegate*)[UIApplication sharedApplication].delegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    application.statusBarStyle = UIStatusBarStyleLightContent;
    [self installBuiltInWatchfaces];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (NSURL*)documentsURL {
    return [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
}

- (NSArray<PBWBundle*>*)availableWatchfaces {
    return [PBWBundle bundlesAtURL:self.documentsURL];
}

- (void)installBuiltInWatchfaces {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger builtInWatchfacesVersion = 1;
    NSInteger installedBuiltInWatchfaces = [userDefaults integerForKey:@"installedBuiltInWatchfaces"];
    if (installedBuiltInWatchfaces >= builtInWatchfacesVersion) return;
    NSURL *builtInWatchfacesURL = [[NSBundle mainBundle].resourceURL URLByAppendingPathComponent:@"Faces" isDirectory:YES];
    NSURL *documentsURL = self.documentsURL;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<PBWBundle*> *builtInWatchfaces = [PBWBundle bundlesAtURL:builtInWatchfacesURL];
    for (PBWBundle *bundle in builtInWatchfaces) {
        NSURL *installURL = [documentsURL URLByAppendingPathComponent:bundle.bundleURL.lastPathComponent];
        if (installedBuiltInWatchfaces == -1) [fm removeItemAtURL:installURL error:nil];
        [fm copyItemAtURL:bundle.bundleURL toURL:installURL error:nil];
    }
    [userDefaults setInteger:builtInWatchfacesVersion forKey:@"installedBuiltInWatchfaces"];
}

@end
