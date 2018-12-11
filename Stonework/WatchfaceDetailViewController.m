//
//  WatchfaceDetailViewController.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 08/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "WatchfaceDetailViewController.h"
#import "StoreViewController.h"
#import "PBWKit.h"

@import WatchConnectivity;

@interface WatchfaceDetailViewController () <WCSessionDelegate>

@end

@implementation WatchfaceDetailViewController
{
    BOOL activatingWatchface;
    PBWRuntime *runtime;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareWatchface:)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    PBWBundle *wf = self.watchfaceBundle;
    self.navigationItem.title = wf.shortName;
    self.nameLabel.text = wf.shortName;
    self.developerLabel.text = wf.companyName;
    self.longNameLabel.text = wf.longName;
    self.infoDeveloperLabel.text = wf.companyName;
    self.versionLabel.text = wf.versionLabel;
    
    [self startEmulator];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    activatingWatchface = NO;
    [runtime stop];
    [runtime.screenView removeFromSuperview];
}

- (void)startEmulator {
    PBWApp *app = [[PBWApp alloc] initWithBundle:self.watchfaceBundle platform:PBWPlatformTypeBasalt];
    if (app == nil) app = [[PBWApp alloc] initWithBundle:self.watchfaceBundle platform:PBWPlatformTypeAplite];
    if (app) {
        runtime = [[PBWRuntime alloc] initWithApp:app];
        UIView *screenView = (UIView*)runtime.screenView;
        [self.imageView addSubview:screenView];
        screenView.frame = self.imageView.bounds;
        [runtime run];
    }
}

- (void)shareWatchface:(id)sender {
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.watchfaceBundle.bundleURL] applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (IBAction)deleteWatchface:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Do you want to delete this watchface?" message:@"You cannot undo this action." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSError *deleteError = nil;
        if ([[NSFileManager defaultManager] removeItemAtURL:self.watchfaceBundle.bundleURL error:&deleteError]) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self failWithTitle:@"Error deleting watchface" message:deleteError.localizedDescription handler:nil];
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)activateWatchface:(id)sender {
    if (![WCSession isSupported]) {
        [self failWithTitle:@"Not supported" message:@"Apple Watch connectivity is not supported on this device." handler:nil];
        return;
    }
    
    WCSession *session = [WCSession defaultSession];
    session.delegate = self;
    if (session.activationState != WCSessionActivationStateActivated) {
        activatingWatchface = YES;
        [session activateSession];
    } else {
        [session transferFile:_watchfaceBundle.bundleURL metadata:nil];
    }
}

- (void)failWithTitle:(NSString*)title message:(NSString*)message handler:(void (^ __nullable)(UIAlertAction *action))handler {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self failWithTitle:title message:message handler:handler];
        });
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:handler]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[StoreViewController class]]) {
        StoreViewController *storeViewController = (StoreViewController*)segue.destinationViewController;
        NSString *stringURL = [@"https://apps.rebble.io/en_US/search/watchfaces/?query=" stringByAppendingString:_watchfaceBundle.UUID.UUIDString.lowercaseString];
        storeViewController.landingURL = [NSURL URLWithString:stringURL];
    }
}

#pragma mark <WCSessionDelegate>

- (void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError *)error {
    if (!activatingWatchface) return;
    if (error) {
        [self failWithTitle:@"Error" message:error.localizedDescription handler:nil];
        return;
    }
    if (activationState != WCSessionActivationStateActivated) {
        [self failWithTitle:@"Error" message:@"Could not connect to Apple Watch." handler:nil];
        return;
    }
    [session transferFile:_watchfaceBundle.bundleURL metadata:nil];
}

- (void)sessionDidBecomeInactive:(WCSession *)session {
    
}

- (void)sessionDidDeactivate:(WCSession *)session {
    
}

- (void)session:(WCSession *)session didFinishFileTransfer:(WCSessionFileTransfer *)fileTransfer error:(NSError *)error {
    activatingWatchface = NO;
}

#pragma mark <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger result = [super tableView:tableView numberOfRowsInSection:section];
    if (section == 1 /*&& !self.watchfaceBundle.configurable*/) {
        result -= 1;
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (/*!self.watchfaceBundle.configurable &&*/ indexPath.section == 1) {
        indexPath = [NSIndexPath indexPathForItem:indexPath.item+1 inSection:indexPath.section];
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

@end
