//
//  IntentHandler.swift
//  IntentExtension
//
//  Created by Jesús A. Álvarez on 31/10/2020.
//  Copyright © 2020 namedfork. All rights reserved.
//

import Intents

class IntentHandler: INExtension, ConfigurationIntentHandling {
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
    let appGroup = (Bundle.main.object(forInfoDictionaryKey: "ALTAppGroups") as? [String])?.first
    
    var sharedDefaults: UserDefaults {
        get {
            guard let appGroup = appGroup,
                  let sharedDefaults = UserDefaults(suiteName: appGroup) else {
                return UserDefaults.standard
            }
            return sharedDefaults
        }
    }
    
    func previewImage(watchfaceFileName: String) -> INImage? {
        guard let appGroup = appGroup,
              let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
                .appendingPathComponent(watchfaceFileName)
                .appendingPathExtension("preview") else {
            return nil
        }
        return INImage(url: url)
    }
    
    func provideWatchfaceOptionsCollection(for intent: ConfigurationIntent, with completion: @escaping (INObjectCollection<Watchface>?, Error?) -> Void) {
        guard let watchfaces: [String: [String: Any]] = sharedDefaults.object(forKey: "AvailableWatchfaces") as? [String : [String: Any]] else {
            return
        }
        
        completion(INObjectCollection(items: watchfaces.map({ (fileName: String, value: [String: Any]) -> Watchface in
            return Watchface(identifier: fileName,
                             display:
                                (value["longName"] as? String) ??
                                (value["shortName"] as? String) ??
                                fileName,
                             subtitle:
                                value["companyName"] as? String,
                             image: previewImage(watchfaceFileName: fileName))
        }).sorted(by: { $0.displayString.compare($1.displayString) == .orderedAscending })), nil)
    }
    
    func resolveWatchface(for intent: ConfigurationIntent, with completion: @escaping (WatchfaceResolutionResult) -> Void) {
        
    }
}
