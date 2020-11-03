//
//  AppDelegate.swift
//  Stonework
//
//  Created by Jesús A. Álvarez on 03/11/2020.
//  Copyright © 2020 namedfork. All rights reserved.
//

import Foundation
import UIKit
#if !targetEnvironment(macCatalyst)
import WidgetKit
#endif

@objc(AppDelegateDelegate) class AppDelegateDelegate : AppDelegate {
    override func applicationWillResignActive(_ application: UIApplication) {
        super.applicationWillResignActive(application)
        #if !targetEnvironment(macCatalyst)
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        #endif
    }
}
