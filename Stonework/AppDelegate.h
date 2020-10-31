//
//  AppDelegate.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 14/10/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PBWBundle;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (instancetype)sharedInstance;

@end

