//
//  WatchfacesCollectionViewLayout.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 06/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "WatchfacesCollectionViewLayout.h"

@implementation WatchfacesCollectionViewLayout

- (void)prepareLayout {
    CGFloat availableWidth = self.collectionViewContentSize.width - 1;
    CGFloat columns = floor(availableWidth / 160.0);
    self.itemSize = CGSizeMake(availableWidth / columns, 130.0);
    self.minimumInteritemSpacing = 1.0;
    self.minimumLineSpacing = 1.0;
}

- (void)prepareForInterfaceBuilder {
    [self prepareLayout];
}

@end
