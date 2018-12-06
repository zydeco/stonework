//
//  WatchfaceCollectionViewCell.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 06/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PBWBundle;

NS_ASSUME_NONNULL_BEGIN

@interface WatchfaceCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, retain) PBWBundle *watchfaceBundle;

@end

NS_ASSUME_NONNULL_END
