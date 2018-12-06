//
//  WatchfaceCollectionViewCell.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 06/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "WatchfaceCollectionViewCell.h"
#import "PBWBundle.h"
#import "PBWApp.h"
#import "PBWRuntime.h"

@implementation WatchfaceCollectionViewCell
{
    PBWRuntime *runtime;
}

- (void)clearRuntime {
    if (runtime) {
        [runtime stop];
        [runtime.screenView removeFromSuperview];
        runtime = nil;
    }
}
- (void)setWatchfaceBundle:(PBWBundle *)watchfaceBundle {
    _watchfaceBundle = watchfaceBundle;
    self.titleLabel.text = watchfaceBundle.shortName;
    self.subtitleLabel.text = watchfaceBundle.companyName;
    
    if (runtime)
    [runtime stop];
    PBWApp *app = [[PBWApp alloc] initWithBundle:watchfaceBundle platform:PBWPlatformTypeBasalt];
    if (app == nil) app = [[PBWApp alloc] initWithBundle:watchfaceBundle platform:PBWPlatformTypeAplite];
    if (app) {
        runtime = [[PBWRuntime alloc] initWithApp:app];
        UIView *screenView = (UIView*)runtime.screenView;
        [self.imageView addSubview:screenView];
        screenView.frame = self.imageView.bounds;
        [runtime run];
    }
}

@end
