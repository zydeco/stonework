//
//  StoreViewController.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 08/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <UIKit/UIKit.h>

@import WebKit;

NS_ASSUME_NONNULL_BEGIN

@interface StoreViewController : UIViewController <WKUIDelegate, WKNavigationDelegate>

@property (nonatomic, weak) IBOutlet WKWebView *webView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *backButton, *forwardButton, *actionButton;

@end

NS_ASSUME_NONNULL_END
