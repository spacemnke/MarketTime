import SwiftUI

// MARK: - iOS Main View

struct ContentView: View {
    @ObservedObject var timer: MarketTimer

    private let updateTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Terminal green palette (matches macOS version)
    private let terminalGreen = Color(red: 0.2, green: 1.0, blue: 0.2)
    private let dimGreen = Color(red: 0.1, green: 0.5, blue: 0.1)
    private let faintGreen = Color(red: 0.06, green: 0.2, blue: 0.06)
    private let bgColor = Color.black

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: geo.size.height * 0.06)
                    headerSection(geo: geo)
                    statusIndicator
                    divider
                    countdownSection(geo: geo)
                    divider
                    infoSection
                    Spacer(minLength: geo.size.height * 0.06)
                }
                .padding(.horizontal, 24)
                .frame(minHeight: geo.size.height)
            }
        }
        .background(bgColor)
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(terminalGreen)
                .frame(width: 8, height: 8)
                .shadow(color: terminalGreen.opacity(0.8), radius: 4)
                .padding(.top, 14)
                .padding(.trailing, 14)
        }
        .onReceive(updateTimer) { _ in
            timer.update()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            timer.update()
        }
    }

    // MARK: - Header

    private func headerSection(geo: GeometryProxy) -> some View {
        let fontSize: CGFloat = geo.size.width < 380 ? 20 : 24
        return VStack(spacing: 4) {
            Text("NEW YORK STOCK")
                .font(.system(size: fontSize, weight: .heavy, design: .monospaced))
                .foregroundColor(terminalGreen)
                .shadow(color: terminalGreen.opacity(0.3), radius: 4)
            Text("EXCHANGE")
                .font(.system(size: fontSize, weight: .heavy, design: .monospaced))
                .foregroundColor(terminalGreen)
                .shadow(color: terminalGreen.opacity(0.3), radius: 4)
        }
        .padding(.bottom, 14)
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(timer.isMarketOpen ? Color.green : Color.red)
                .frame(width: 12, height: 12)
                .shadow(color: timer.isMarketOpen ? Color.green.opacity(0.8) : Color.red.opacity(0.8), radius: 6)
            Text(timer.statusText)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(terminalGreen)
        }
        .padding(.bottom, 16)
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(dimGreen.opacity(0.6))
            .frame(height: 1)
            .padding(.horizontal, 10)
            .padding(.vertical, 16)
    }

    // MARK: - Countdown

    private func countdownSection(geo: GeometryProxy) -> some View {
        let segmentHeight: CGFloat = min(geo.size.width * 0.16, 72)
        return VStack(spacing: 14) {
            Text(timer.countdownLabel)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(terminalGreen)
                .tracking(2)

            SevenSegmentDisplay(
                timer.countdownString,
                height: segmentHeight,
                activeColor: terminalGreen,
                inactiveColor: faintGreen
            )
            .shadow(color: terminalGreen.opacity(0.5), radius: 8)
            .shadow(color: terminalGreen.opacity(0.25), radius: 18)
        }
    }

    // MARK: - Info Rows

    private var infoSection: some View {
        VStack(spacing: 10) {
            iOSInfoRow(label: "LOCAL TIME [\(timer.localTimeZoneAbbr)]", value: timer.currentTimeLocal, color: terminalGreen)
            iOSInfoRow(label: "CURRENT TIME [EST]", value: timer.currentTimeEST, color: terminalGreen)
            iOSInfoRow(label: "MARKET HOURS", value: "09:30 - 16:00", color: terminalGreen)
            iOSInfoRow(label: "NEXT TRADING DAY", value: timer.nextTradingDay, color: terminalGreen)
        }
    }
}

// MARK: - Info Row Component (iOS)

private struct iOSInfoRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(color)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(color)
        }
    }
}
