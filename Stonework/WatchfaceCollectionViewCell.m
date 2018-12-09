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
#import "NSFileManager+ExtendedAttributes.h"

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

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageView.image = nil;
}

- (void)setWatchfaceBundle:(PBWBundle *)watchfaceBundle {
    _watchfaceBundle = watchfaceBundle;
    self.titleLabel.text = watchfaceBundle.shortName;
    self.subtitleLabel.text = watchfaceBundle.companyName;
    
    NSData *previewData = [[NSFileManager defaultManager] extendedAttribute:@"net.namedfork.stonework.preview" atPath:_watchfaceBundle.bundleURL.path traverseLink:NO error:NULL];
    self.imageView.image = [UIImage imageWithData:previewData];
}

@end
