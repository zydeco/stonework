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

extension UIImage {
    func averageColor(forEdge edge: UIRectEdge) -> UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        guard edge.rawValue.nonzeroBitCount == 1 else { return nil }
        let extentVector: CIVector
        let extent = inputImage.extent
        switch edge {
        case .top:
            extentVector = CIVector(x: extent.minX, y: extent.minY, z: extent.width, w: 1.0)
        case .left:
            extentVector = CIVector(x: extent.minX, y: extent.minY, z: 1.0, w: extent.height)
        case .bottom:
            extentVector = CIVector(x: extent.minX + extent.width - 1.0, y: extent.minY, z: extent.width, w: 1.0)
        case .right:
            extentVector = CIVector(x: extent.minX, y: extent.minY + extent.height - 1.0, z: 1.0, w: extent.height)
        default:
            fatalError()
        }

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
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
            backgroundColor: Color(image.averageColor(forEdge: .left) ?? .black),
            configuration: configuration
        )
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        guard let fileName = configuration.watchface?.identifier else {
            return
        }
        
        let watchfaceURL = PBWManager.default().documentsURL.appendingPathComponent(fileName)
        
        // render times
        if let bundle = PBWBundle(url: watchfaceURL),
           let app = PBWApp(bundle: bundle, platform: .basalt) ?? PBWApp(bundle: bundle, platform: .aplite) {
            let runtime = PBWRuntime(app: app)
            runtime.run()
            
            // the present
            let now = Date()
            
            // the times
            let canUpdateEverySecond = configuration.secondlyUpdates?.boolValue ?? false
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
        let image = Image(uiImage: entry.image ?? UIImage(systemName: "xmark.octagon")!).resizable()
        switch entry.configuration.scale {
        case .fill:
            image.scaledToFill()
        default:
            image.scaledToFit()
        }
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
        .configurationDisplayName("Watchface")
        .description("A widget displaying a Pebble watch face")
        .supportedFamilies([.systemLarge, .systemSmall])
    }
}
