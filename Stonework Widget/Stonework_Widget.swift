//
//  Stonework_Widget.swift
//  Stonework Widget
//
//  Created by Jesús A. Álvarez on 11/10/2020.
//  Copyright © 2020 namedfork. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents

extension PBWRuntime {
    func screenImage(forDate date: Date) -> UIImage {
        self.timeOverride = date
        self.tick()
        self.drawScreenView(with: nil)
        let image = self.screenImage as! UIImage
        self.timeOverride = nil
        return image
    }
}

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(),
                    image: nil,
                    backgroundColor: Color.black,
                    configuration: ConfigurationIntent()
        )
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(
            date: Date(),
            image: nil,
            backgroundColor: Color.black,
            configuration: configuration
        )
        completion(entry)
    }
    
    func getEntry(for configuration: ConfigurationIntent, date: Date, runtime: PBWRuntime) -> SimpleEntry {
        let image = runtime.screenImage(forDate: date)
        return SimpleEntry(
            date: date,
            image: image,
            backgroundColor: Color.black,
            configuration: configuration
        )
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        #if targetEnvironment(simulator)
        let container: URL? = (URL(fileURLWithPath: "/Users/zydeco/Library/Developer/CoreSimulator/Devices/D1099B9F-FC60-4F35-8350-9671746A91C6/data/Containers/Shared/AppGroup/4F3401A6-B3C0-4BF4-9B24-2DFC972A7CC8/"))
        #else
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.net.namedfork.stonework")
        #endif
        
        
        // render times
        if let bundleURL = container?.appendingPathComponent("widget.pbw"),
           let bundle = PBWBundle(url: bundleURL),
           let app = PBWApp(bundle: bundle, platform: .basalt) {
            let runtime = PBWRuntime(app: app)
            runtime.run()
            
            // the present
            let now = Date()
            
            // the times
            let canUpdateEverySecond = false
            if runtime.tickServiceUnits.contains(.SECOND_UNIT) && canUpdateEverySecond {
                // update every second
                for secondOffset in 0 ..< 300 {
                    let date = now.advanced(by: TimeInterval(secondOffset))
                    entries.append(getEntry(for: configuration, date: date, runtime: runtime))
                }
            } else {
                // update every minute
                let second = Calendar.current.component(.second, from: now)
                let minute = now.addingTimeInterval(TimeInterval(-second))
                for minuteOffset in 0 ..< 10 {
                    let secondOffset = 60.0 * TimeInterval(minuteOffset)
                    let date = minute.advanced(by: secondOffset)
                    entries.append(getEntry(for: configuration, date: date, runtime: runtime))
                }
            }
            
            runtime.stop()
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let image: UIImage?
    let backgroundColor: Color
    let configuration: ConfigurationIntent
}

struct Stonework_WidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        Image(uiImage: entry.image ?? UIImage(systemName: "xmark.octagon")!).scaledToFill()
    }
}

@main
struct Stonework_Widget: Widget {
    let kind: String = "Stonework_Widget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            Stonework_WidgetEntryView(entry: entry)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(entry.backgroundColor)
        }
        .configurationDisplayName("Watchface Widget")
        .description("This is an example widget.")
    }
}
