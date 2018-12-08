//
//  WatchfaceDetailViewController.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 08/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PBWBundle;

NS_ASSUME_NONNULL_BEGIN

@interface WatchfaceDetailViewController : UITableViewController

@property (nonatomic, retain) PBWBundle *watchfaceBundle;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel, *developerLabel;
@property (nonatomic, weak) IBOutlet UILabel *longNameLabel, *infoDeveloperLabel, *versionLabel;


@end

NS_ASSUME_NONNULL_END
