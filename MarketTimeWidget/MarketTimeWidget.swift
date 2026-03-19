import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct MarketStatusEntry: TimelineEntry {
    let date: Date
    let isMarketOpen: Bool
    let statusText: String
    let countdownString: String
    let nextTradingDay: String
    let marketCloseDate: Date?  // For live countdown via Text(.timer)
    let marketOpenDate: Date?   // For live countdown via Text(.timer)
}

// MARK: - Timeline Provider

struct MarketTimeProvider: TimelineProvider {
    func placeholder(in context: Context) -> MarketStatusEntry {
        MarketStatusEntry(
            date: Date(),
            isMarketOpen: false,
            statusText: "MARKET CLOSED",
            countdownString: "00:00:00",
            nextTradingDay: "MONDAY",
            marketCloseDate: nil,
            marketOpenDate: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MarketStatusEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MarketStatusEntry>) -> Void) {
        let now = Date()
        var entries: [MarketStatusEntry] = []

        // Generate entries every minute for the next 15 minutes
        for minuteOffset in 0..<15 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: now)!
            entries.append(makeEntry(for: entryDate))
        }

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now)!
        completion(Timeline(entries: entries, policy: .after(nextUpdate)))
    }

    private func makeEntry(for date: Date) -> MarketStatusEntry {
        let timer = MarketTimer()
        timer.update(for: date)

        // Calculate target dates for live countdown
        var marketCloseDate: Date? = nil
        var marketOpenDate: Date? = nil

        if timer.isMarketOpen {
            // Market is open — countdown to close
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "America/New_York")!
            var components = cal.dateComponents([.year, .month, .day], from: date)
            components.hour = 16
            components.minute = 0
            components.second = 0
            marketCloseDate = cal.date(from: components)
        } else {
            // Market is closed — countdown to next open
            // Use the countdown seconds to derive the target date
            let parts = timer.countdownString.split(separator: ":").compactMap { Int($0) }
            if parts.count == 3 {
                let totalSeconds = parts[0] * 3600 + parts[1] * 60 + parts[2]
                marketOpenDate = date.addingTimeInterval(Double(totalSeconds))
            }
        }

        return MarketStatusEntry(
            date: date,
            isMarketOpen: timer.isMarketOpen,
            statusText: timer.statusText,
            countdownString: timer.countdownString,
            nextTradingDay: timer.nextTradingDay,
            marketCloseDate: marketCloseDate,
            marketOpenDate: marketOpenDate
        )
    }
}

// MARK: - Widget Definition

struct MarketTimeWidget: Widget {
    let kind: String = "MarketTimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MarketTimeProvider()) { entry in
            MarketTimeWidgetEntryView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Market Status")
        .description("NYSE market status and countdown timer.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
        ])
    }
}

// MARK: - Widget Bundle (entry point)

@main
struct MarketTimeWidgetBundle: WidgetBundle {
    var body: some Widget {
        MarketTimeWidget()
    }
}
