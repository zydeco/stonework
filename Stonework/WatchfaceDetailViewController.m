//
//  WatchfaceDetailViewController.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 08/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "WatchfaceDetailViewController.h"
#import "PBWKit.h"

@interface WatchfaceDetailViewController ()

@end

@implementation WatchfaceDetailViewController

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
}

- (void)shareWatchface:(id)sender {
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.watchfaceBundle.bundleURL] applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (IBAction)deleteWatchface:(id)sender {
    
}

- (IBAction)activateWatchface:(id)sender {
    
}

#pragma mark <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger result = [super tableView:tableView numberOfRowsInSection:section];
    if (section == 1 && !self.watchfaceBundle.configurable) {
        result -= 1;
    }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.watchfaceBundle.configurable && indexPath.section == 1) {
        indexPath = [NSIndexPath indexPathForItem:indexPath.item+1 inSection:indexPath.section];
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}
@end
