//
//  WatchfacesViewController.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 05/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PBWBundle;

NS_ASSUME_NONNULL_BEGIN

@interface WatchfacesViewController : UICollectionViewController

+ (void)confirmDeletionOfWatchface:(PBWBundle*)watchfaceBundle fromViewController:(UIViewController*)viewController completion:(void(^)(NSError *error))completion;

@end

NS_ASSUME_NONNULL_END
