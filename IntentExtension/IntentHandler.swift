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
    
    func urlForPreview(fileName: String) -> URL? {
        guard let appGroup = appGroup,
              let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            return nil
        }
        return url.appendingPathComponent(fileName).appendingPathExtension("preview")
    }
    
    func provideWatchfaceOptionsCollection(for intent: ConfigurationIntent, with completion: @escaping (INObjectCollection<Watchface>?, Error?) -> Void) {
        guard let watchfaces: [String: [String: Any]] = sharedDefaults.object(forKey: "AvailableWatchfaces") as? [String : [String: Any]] else {
            return
        }
        
        completion(INObjectCollection(items: watchfaces.map({ (fileName: String, value: [String: Any]) -> Watchface in
            let shortName = value["shortName"] as? String
            let companyName = value["companyName"] as? String
            let previewURL = urlForPreview(fileName: fileName)
            let preview = (previewURL != nil) ? INImage(url:previewURL!) : nil
            return Watchface(identifier: fileName, display: shortName ?? fileName, subtitle: companyName, image: preview)
        }).sorted(by: { $0.displayString.compare($1.displayString) == .orderedAscending })), nil)
    }
    
    func resolveWatchface(for intent: ConfigurationIntent, with completion: @escaping (WatchfaceResolutionResult) -> Void) {
        
    }
}
