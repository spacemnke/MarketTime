import SwiftUI
import WidgetKit

// MARK: - Widget Entry View

struct MarketTimeWidgetEntryView: View {
    var entry: MarketStatusEntry
    @Environment(\.widgetFamily) var family

    private let terminalGreen = Color(red: 0.2, green: 1.0, blue: 0.2)
    private let dimGreen = Color(red: 0.1, green: 0.5, blue: 0.1)
    private let faintGreen = Color(red: 0.06, green: 0.2, blue: 0.06)

    var body: some View {
        switch family {
        case .accessoryCircular:
            lockScreenCircular
        case .accessoryRectangular:
            lockScreenRectangular
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    // MARK: - Lock Screen Circular

    private var lockScreenCircular: some View {
        VStack(spacing: 2) {
            Image(systemName: entry.isMarketOpen
                  ? "chart.line.uptrend.xyaxis"
                  : "moon.zzz")
                .font(.system(size: 16))
            Text(entry.isMarketOpen ? "OPEN" : "CLSD")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
        }
    }

    // MARK: - Lock Screen Rectangular

    private var lockScreenRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: entry.isMarketOpen
                      ? "chart.line.uptrend.xyaxis"
                      : "moon.zzz")
                    .font(.system(size: 11))
                Text("NYSE \(entry.isMarketOpen ? "OPEN" : "CLOSED")")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
            }
            if let target = entry.isMarketOpen ? entry.marketCloseDate : entry.marketOpenDate {
                Text(target, style: .timer)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .monospacedDigit()
            } else {
                Text(entry.countdownString)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
            }
        }
    }

    // MARK: - Home Screen Small

    private var smallWidget: some View {
        VStack(spacing: 8) {
            // Status
            HStack(spacing: 6) {
                Circle()
                    .fill(entry.isMarketOpen ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                    .shadow(color: (entry.isMarketOpen ? Color.green : Color.red).opacity(0.8), radius: 4)
                Text(entry.isMarketOpen ? "OPEN" : "CLOSED")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(terminalGreen)
            }

            // Countdown
            if let target = entry.isMarketOpen ? entry.marketCloseDate : entry.marketOpenDate {
                Text(target, style: .timer)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(terminalGreen)
                    .monospacedDigit()
                    .shadow(color: terminalGreen.opacity(0.5), radius: 6)
            } else {
                Text(entry.countdownString)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(terminalGreen)
                    .shadow(color: terminalGreen.opacity(0.5), radius: 6)
            }

            // Next trading day
            Text(entry.nextTradingDay)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(dimGreen)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Home Screen Medium

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            // Left: Status
            VStack(alignment: .leading, spacing: 8) {
                Text("NYSE")
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundColor(terminalGreen)

                HStack(spacing: 6) {
                    Circle()
                        .fill(entry.isMarketOpen ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                        .shadow(color: (entry.isMarketOpen ? Color.green : Color.red).opacity(0.8), radius: 4)
                    Text(entry.statusText)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(terminalGreen)
                }

                Text(entry.nextTradingDay)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(dimGreen)
            }

            Rectangle()
                .fill(dimGreen.opacity(0.4))
                .frame(width: 1)
                .padding(.vertical, 8)

            // Right: Countdown
            VStack(spacing: 6) {
                Text(entry.isMarketOpen ? "CLOSES IN" : "OPENS IN")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(dimGreen)

                if let target = entry.isMarketOpen ? entry.marketCloseDate : entry.marketOpenDate {
                    Text(target, style: .timer)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(terminalGreen)
                        .monospacedDigit()
                        .shadow(color: terminalGreen.opacity(0.5), radius: 6)
                } else {
                    Text(entry.countdownString)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(terminalGreen)
                        .shadow(color: terminalGreen.opacity(0.5), radius: 6)
                }

                Text("09:30 – 16:00 ET")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundColor(faintGreen)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
