//
//  DiceWidget.swift
//  zaruriWidget
//
//  Created by ax on 06.01.2026.
//

import WidgetKit
import SwiftUI

@available(iOS 14.0, *)
struct DiceWidget: Widget {
    let kind: String = "DiceWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DiceTimelineProvider()) { entry in
            DiceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Zaruri")
        .description("Aruncă zarurile rapid sau vezi ultimul rezultat.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@available(iOS 14.0, *)
struct DiceTimelineProvider: TimelineProvider {
    typealias Entry = DiceEntry
    
    func placeholder(in context: Context) -> DiceEntry {
        DiceEntry(date: Date(), lastRoll: DiceRoll(values: [4, 5]))
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DiceEntry) -> Void) {
        let entry = DiceEntry(
            date: Date(),
            lastRoll: loadLastRoll()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DiceEntry>) -> Void) {
        let entry = DiceEntry(
            date: Date(),
            lastRoll: loadLastRoll()
        )
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func loadLastRoll() -> DiceRoll? {
        let history = UserDefaultsManager.shared.loadHistory()
        return history.first
    }
}

@available(iOS 14.0, *)
struct DiceEntry: TimelineEntry {
    let date: Date
    let lastRoll: DiceRoll?
}

@available(iOS 14.0, *)
struct DiceWidgetEntryView: View {
    var entry: DiceTimelineProvider.Entry
    
    var body: some View {
        VStack(spacing: 8) {
            if let roll = entry.lastRoll {
                Text("Ultimul rezultat")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(roll.formattedValues)
                    .font(.title)
                    .fontWeight(.bold)
                
                if roll.numberOfDice > 1 {
                    Text("Total: \(roll.total)")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            } else {
                Text("Zaruri")
                    .font(.headline)
                
                Image(systemName: "dice.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
}

@available(iOS 14.0, *)
struct DiceWidget_Previews: PreviewProvider {
    static var previews: some View {
        DiceWidgetEntryView(
            entry: DiceEntry(
                date: Date(),
                lastRoll: DiceRoll(values: [3, 4, 5])
            )
        )
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}



