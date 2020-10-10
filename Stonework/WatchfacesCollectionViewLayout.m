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
    CGFloat availableWidth = self.collectionViewContentSize.width;
    CGFloat columns = floor(availableWidth / 160.0);
    CGFloat spacing = 1.0;
    self.itemSize = CGSizeMake(floor((availableWidth - spacing * (columns - 1)) / columns), 130.0);
    self.estimatedItemSize = self.itemSize;
    self.minimumInteritemSpacing = spacing;
    self.minimumLineSpacing = spacing;
}

- (void)prepareForInterfaceBuilder {
    [self prepareLayout];
}

@end
