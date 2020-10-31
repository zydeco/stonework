//
//  AppDelegate.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 14/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "AppDelegate.h"
#import "PBWKit.h"
#import "WatchfaceDetailViewController.h"
#import <objc/runtime.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

+ (void)load
{
#if TARGET_OS_MACCATALYST
    Method method = class_getInstanceMethod(objc_getClass("UINSSceneView"), NSSelectorFromString(@"scaleFactor"));
    method_setImplementation(method, imp_implementationWithBlock(^{ return (CGFloat)1.0; }));
#endif
}

+ (instancetype)sharedInstance {
    return (AppDelegate*)[UIApplication sharedApplication].delegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self installBuiltInWatchfaces];
#if TARGET_OS_MACCATALYST
    for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            scene.sizeRestrictions.minimumSize = CGSizeMake(320.0, 480.0);
            scene.titlebar.titleVisibility = UITitlebarTitleVisibilityHidden;
            scene.titlebar.toolbar = nil;
        }
    }
#endif
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

- (void)installBuiltInWatchfaces {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger builtInWatchfacesVersion = 1;
    NSInteger installedBuiltInWatchfaces = [userDefaults integerForKey:@"installedBuiltInWatchfaces"];
    if (installedBuiltInWatchfaces >= builtInWatchfacesVersion) return;
    NSURL *builtInWatchfacesURL = [[NSBundle mainBundle].resourceURL URLByAppendingPathComponent:@"Faces" isDirectory:YES];
    NSURL *documentsURL = [PBWManager defaultManager].documentsURL;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<PBWBundle*> *builtInWatchfaces = [PBWBundle bundlesAtURL:builtInWatchfacesURL];
    for (PBWBundle *bundle in builtInWatchfaces) {
        NSURL *installURL = [documentsURL URLByAppendingPathComponent:bundle.bundleURL.lastPathComponent];
        if (installedBuiltInWatchfaces == -1) [fm removeItemAtURL:installURL error:nil];
        [fm copyItemAtURL:bundle.bundleURL toURL:installURL error:nil];
    }
    [userDefaults setInteger:builtInWatchfacesVersion forKey:@"installedBuiltInWatchfaces"];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertWithTitle:title message:message];
        });
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    UIViewController *controller = self.window.rootViewController;
    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }
    [controller presentViewController:alert animated:YES completion:nil];
}

- (BOOL)importFileToDocuments:(NSURL *)url copy:(BOOL)copy {
    if (url.fileURL) {
        // opening file
        NSString *documentsPath = [PBWManager defaultManager].documentsURL.path;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *fileName = url.path.lastPathComponent;
        NSString *destinationPath = [documentsPath stringByAppendingPathComponent:fileName];
        NSError *error = NULL;
        NSInteger tries = 1;
        while ([fileManager fileExistsAtPath:destinationPath]) {
            NSString *newFileName;
            if (fileName.pathExtension.length > 0) {
                newFileName = [NSString stringWithFormat:@"%@ %d.%@", fileName.stringByDeletingPathExtension, (int)tries, fileName.pathExtension];
            } else {
                newFileName = [NSString stringWithFormat:@"%@ %d", fileName, (int)tries];
            }
            destinationPath = [documentsPath stringByAppendingPathComponent:newFileName];
            tries++;
        }
        if (copy) {
            [fileManager copyItemAtPath:url.path toPath:destinationPath error:&error];
        } else {
            [fileManager moveItemAtPath:url.path toPath:destinationPath error:&error];
        }
        if (error) {
            [self showAlertWithTitle:fileName message:error.localizedFailureReason];
        } else {
            PBWBundle *watchfaceBundle = [PBWBundle bundleWithURL:[NSURL fileURLWithPath:destinationPath]];
            [self showDetailForBundle:watchfaceBundle];
        }
    }
    return YES;
}

- (void)showDetailForBundle:(PBWBundle*)watchfaceBundle {
    UINavigationController *controller = (UINavigationController*)self.window.rootViewController;
    WatchfaceDetailViewController *detailViewController = [controller.storyboard instantiateViewControllerWithIdentifier:@"watchfaceDetail"];
    detailViewController.watchfaceBundle = watchfaceBundle;
    [controller popToRootViewControllerAnimated:NO];
    [controller pushViewController:detailViewController animated:YES];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if (url.fileURL) {
        // opening file
        NSString *documentsPath = [PBWManager defaultManager].documentsURL.path;
        if ([url.path.stringByStandardizingPath hasPrefix:documentsPath]) {
            // already in documents - show
            PBWBundle *watchfaceBundle = [PBWBundle bundleWithURL:url];
            if (watchfaceBundle.isWatchFace) {
                [self showDetailForBundle:watchfaceBundle];
            } else {
                [self showAlertWithTitle:@"Unsupported Application Type" message:@"Only watchface applications are supported."];
            }
        } else if ([options[UIApplicationOpenURLOptionsOpenInPlaceKey] boolValue]) {
            // not in documents - copy
            [url startAccessingSecurityScopedResource];
            [self importFileToDocuments:url copy:YES];
            [url stopAccessingSecurityScopedResource];
        } else {
            return [self importFileToDocuments:url copy:NO];
        }
    }
    return YES;
}

@end
