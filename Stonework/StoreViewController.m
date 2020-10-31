//
//  StoreViewController.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 08/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "StoreViewController.h"
#import "AppDelegate.h"
#import "PBWKit.h"
#import "PBWBundle+Preview.h"

static NSArray *observedWebViewKeys = nil;

@interface StoreViewController ()

@end

@implementation StoreViewController
{
    UIAlertController *downloadProgressController;
    NSURLSessionDownloadTask *downloadTask;
    UIBarButtonItem *stopButton, *reloadButton;
    NSURL *watchfacesURL, *searchURL;
}

+ (NSURL*)URLForSearchingStoreWithUUID:(NSUUID *)UUID {
    NSString *stringURL = [@"https://apps.rebble.io/en_US/search/watchfaces/?query=" stringByAppendingString:UUID.UUIDString.lowercaseString];
    return [NSURL URLWithString:stringURL];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.webView.navigationDelegate = self;
    self.webView.UIDelegate = self;
#if TARGET_OS_MACCATALYST
    self.webView.customUserAgent = @"Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/86.0.4240.77 Mobile/15E148 Safari/604.1";
#endif
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        observedWebViewKeys = @[@"canGoBack", @"canGoForward", @"title", @"loading"];
    });
    reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload:)];
    stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stop:)];
    self.navigationItem.rightBarButtonItem = reloadButton;
    watchfacesURL = [NSURL URLWithString:@"https://apps.rebble.io/en_US/watchfaces"];
    searchURL = [NSURL URLWithString:@"https://apps.rebble.io/en_US/search/watchfaces"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSURLRequest *request = [NSURLRequest requestWithURL:_landingURL ?: watchfacesURL];
    [self.webView loadRequest:request];
    for (NSString *key in observedWebViewKeys) {
        [self.webView addObserver:self forKeyPath:key options:0 context:NULL];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    for (NSString *key in observedWebViewKeys) {
        [self.webView removeObserver:self forKeyPath:key];
    };
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.webView) {
        if ([keyPath isEqualToString:@"canGoBack"]) {
            self.backButton.enabled = self.webView.canGoBack;
        } else if ([keyPath isEqualToString:@"canGoForward"]) {
            self.forwardButton.enabled = self.webView.canGoForward;
        } else if ([keyPath isEqualToString:@"title"]) {
            self.navigationItem.title = self.webView.title;
        } else if ([keyPath isEqualToString:@"loading"]) {
            self.navigationItem.rightBarButtonItem = self.webView.loading ? stopButton : reloadButton;
        }
    }
}

#pragma mark - Navigation

- (IBAction)navigateBack:(id)sender {
    [self.webView goBack];
}

- (IBAction)navigateForward:(id)sender {
    [self.webView goForward];
}

- (IBAction)shareAction:(id)sender {
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.webView.URL] applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (IBAction)stop:(id)sender {
    [self.webView stopLoading];
}

- (IBAction)reload:(id)sender {
    [self.webView reloadFromOrigin];
}

- (IBAction)search:(id)sender {
    [self.webView loadRequest:[NSURLRequest requestWithURL:searchURL]];
}

- (IBAction)goHome:(id)sender {
    [self.webView loadRequest:[NSURLRequest requestWithURL:watchfacesURL]];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *requestURL = navigationAction.request.URL;
    if ([requestURL.scheme isEqualToString:@"pebble"] && [requestURL.host isEqualToString:@"appstore"]) {
        // get app
        [webView evaluateJavaScript:@"angular.element(document.getElementsByClassName('app-install')).scope().app" completionHandler:^(id _Nullable app, NSError * _Nullable error) {
            [self downloadApp:app];
        }];
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

#pragma mark - App Download

- (void)downloadApp:(NSDictionary*)app {
    // check that app exists
    if (app == nil) {
        [self failWithTitle:@"Error" message:@"Application not found." handler:nil];
        return;
    }
    
    // check that app is a watchface
    if (![app[@"type"] isEqualToString:@"watchface"]) {
        [self failWithTitle:@"Unsupported Application Type" message:@"Only watchface applications are supported." handler:nil];
        return;
    }
    
    // check that URL exists
    NSString *pbwURLString = [app valueForKeyPath:@"latest_release.pbw_file"];
    if (pbwURLString == nil) {
        [self failWithTitle:@"Could not Install" message:@"Install URL not found." handler:nil];
        return;
    }
    
    // is it already installed?
    NSUUID *appUUID = [[NSUUID alloc] initWithUUIDString:app[@"uuid"]];
    NSArray *installedUUIDs = [[PBWManager defaultManager].availableWatchfaces valueForKeyPath:@"@unionOfObjects.UUID"];
    if ([installedUUIDs containsObject:appUUID]) {
        [self failWithTitle:@"Already Installed" message:@"This application is already installed, please remove it to install again." handler:nil];
        return;
    }
    
    // download and install
    NSString *message = [NSString stringWithFormat:@"Downloading %@…", app[@"title"]];
    downloadProgressController = [UIAlertController alertControllerWithTitle:@"Installing" message:message preferredStyle:UIAlertControllerStyleAlert];
    [downloadProgressController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self cancelAppDownload];
    }]];
    [self presentViewController:downloadProgressController animated:YES completion:^{
        NSString *screenshotSize = app[@"screenshot_size"];
        NSString *screenshotURL = screenshotSize ? [[app[@"screenshot_images"] firstObject] valueForKey:screenshotSize] : nil;
        [self downloadAppFromURL:[NSURL URLWithString:pbwURLString] withUUID:appUUID screenshotURL:[NSURL URLWithString:screenshotURL]];
    }];
}

- (void)cancelAppDownload {
    [downloadTask cancel];
}

- (void)downloadAppFromURL:(NSURL*)URL withUUID:(NSUUID*)appUUID screenshotURL:(NSURL*)screenshotURL {
    NSURLSession *session = [NSURLSession sharedSession];
    NSString *fileName = [appUUID.UUIDString stringByAppendingPathExtension:@"pbw"];
    NSURL *installURL = [[PBWManager defaultManager].documentsURL URLByAppendingPathComponent:fileName];
    downloadTask = [session downloadTaskWithURL:URL completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil && location) {
            NSData *screenshotData = [NSData dataWithContentsOfURL:screenshotURL];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSFileManager *fm = [NSFileManager defaultManager];
                NSError *installError = nil;
                if ([fm moveItemAtURL:location toURL:installURL error:&installError]) {
                    [PBWBundle writePreviewData:screenshotData forBundleAtURL:installURL];
                    [self->downloadProgressController dismissViewControllerAnimated:YES completion:^{
                        [self.navigationController popViewControllerAnimated:YES];
                    }];
                } else {
                    [self->downloadProgressController dismissViewControllerAnimated:YES completion:^{
                        [self failWithTitle:@"Error" message:installError.localizedDescription handler:nil];
                    }];
                }
            });
        }
    }];
    [downloadTask resume];
}

- (void)failWithTitle:(NSString*)title message:(NSString*)message handler:(void (^ __nullable)(UIAlertAction *action))handler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:handler]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
