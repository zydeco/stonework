//
//  WatchfaceDetailViewController.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 08/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "WatchfaceDetailViewController.h"
#import "WatchfacesViewController.h"
#import "StoreViewController.h"
#import "PBWKit.h"
#import "PBWBundle+Preview.h"

@import WatchConnectivity;

@interface WatchfaceDetailViewController () <WCSessionDelegate>

@end

@implementation WatchfaceDetailViewController
{
    BOOL activatingWatchface;
    PBWRuntime *runtime;
    WCSession *session;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareWatchface:)];
    if ([WCSession isSupported]) {
        session = [WCSession defaultSession];
        session.delegate = self;
        [session addObserver:self forKeyPath:@"reachable" options:0 context:NULL];
    } else {
        session = nil;
    }
}

- (void)dealloc {
    [session removeObserver:self forKeyPath:@"reachable"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == session && [keyPath isEqual:@"reachable"]) {
        [self performSelectorOnMainThread:@selector(reloadActivateButton) withObject:nil waitUntilDone:NO];
    }
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
    if (session != nil && session.activationState != WCSessionActivationStateActivated) {
        [session activateSession];
    }
    [self reloadActivateButton];
}

- (void)viewWillDisappear:(BOOL)animated {
    if (!self.watchfaceBundle.hasPreview) {
        // screen image is flipped; PNG representation doesn't preserve orientation
        self.watchfaceBundle.previewData = UIImageJPEGRepresentation(runtime.screenImage, 1.0);
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self setInstallingWatchface:NO];
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
    [WatchfacesViewController confirmDeletionOfWatchface:self.watchfaceBundle fromViewController:self completion:^(NSError * _Nonnull error) {
        if (error == nil) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

- (IBAction)activateWatchface:(id)sender {
    [self setInstallingWatchface:YES];
    [self transferWatchface];
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
        storeViewController.landingURL = [StoreViewController URLForSearchingStoreWithUUID:_watchfaceBundle.UUID];
    }
}

#pragma mark <WCSessionDelegate>

- (void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError *)error {
    if (error) {
        [self failWithTitle:@"Error" message:error.localizedDescription handler:nil];
        return;
    } else if (activationState != WCSessionActivationStateActivated) {
        [self failWithTitle:@"Error" message:@"Could not connect to Apple Watch." handler:nil];
        return;
    }
    if (activatingWatchface) {
        [self transferWatchface];
    }
    [self performSelectorOnMainThread:@selector(reloadActivateButton) withObject:nil waitUntilDone:NO];
}

- (void)transferWatchface {
    if (session.activationState != WCSessionActivationStateActivated) {
        [session activateSession];
        return;
    }
    [session.outstandingFileTransfers makeObjectsPerformSelector:@selector(cancel)];
    [session transferFile:_watchfaceBundle.bundleURL metadata:nil];
}

- (void)sessionDidBecomeInactive:(WCSession *)session {
    [self performSelectorOnMainThread:@selector(reloadActivateButton) withObject:nil waitUntilDone:NO];
}

- (void)sessionDidDeactivate:(WCSession *)session {
    [self performSelectorOnMainThread:@selector(reloadActivateButton) withObject:nil waitUntilDone:NO];
}

- (void)session:(WCSession *)session didFinishFileTransfer:(WCSessionFileTransfer *)fileTransfer error:(NSError *)error {
    if (error) {
        [self failWithTitle:@"Error activating watchface" message:error.localizedDescription handler:nil];
    }
    [self setInstallingWatchface:NO];
}

- (BOOL)canInstallWatchface {
    return session != nil && session.activationState == WCSessionActivationStateActivated && session.reachable;
}

- (void)reloadActivateButton {
    BOOL canInstall = [self canInstallWatchface];
    _activateButton.enabled = canInstall;
    _activateButton.alpha = canInstall ? 1.0 : 0.25;
}

- (void)setInstallingWatchface:(BOOL)installing {
    activatingWatchface = installing;
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setInstallingWatchface:installing];
        });
        return;
    }
    _activateButton.hidden = installing;
    if (installing) {
        [_activateIndicator startAnimating];
    } else {
        [_activateIndicator stopAnimating];
    }
}

#pragma mark <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger result = [super tableView:tableView numberOfRowsInSection:section];
    if (section == 1 /*&& !self.watchfaceBundle.configurable*/) {
        // Hide configuration button
        result -= 1;
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 /*&& !self.watchfaceBundle.configurable*/) {
        // Hide configuration button
        indexPath = [NSIndexPath indexPathForItem:indexPath.item+1 inSection:indexPath.section];
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

@end
