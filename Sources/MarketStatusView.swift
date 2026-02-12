import SwiftUI

// MARK: - Main Popover View

struct MarketStatusView: View {
    @ObservedObject var timer: MarketTimer

    // Terminal green palette
    private let terminalGreen = Color(red: 0.2, green: 1.0, blue: 0.2)
    private let dimGreen = Color(red: 0.1, green: 0.5, blue: 0.1)
    private let faintGreen = Color(red: 0.06, green: 0.2, blue: 0.06)
    private let bgColor = Color.black

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            statusIndicator
            divider
            countdownSection
            divider
            infoSection
            quitButton
        }
        .padding(.horizontal, 30)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .frame(width: 420)
        .background(bgColor)
        // Green power dot — top-right corner (matches reference image)
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(terminalGreen)
                .frame(width: 8, height: 8)
                .shadow(color: terminalGreen.opacity(0.8), radius: 4)
                .padding(.top, 14)
                .padding(.trailing, 14)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("NEW YORK STOCK")
                .font(.system(size: 24, weight: .heavy, design: .monospaced))
                .foregroundColor(terminalGreen)
                .shadow(color: terminalGreen.opacity(0.3), radius: 4)
            Text("EXCHANGE")
                .font(.system(size: 24, weight: .heavy, design: .monospaced))
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

    private var countdownSection: some View {
        VStack(spacing: 14) {
            Text(timer.countdownLabel)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(terminalGreen)
                .tracking(2)

            SevenSegmentDisplay(
                timer.countdownString,
                height: 72,
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
            InfoRow(label: "LOCAL TIME [\(timer.localTimeZoneAbbr)]", value: timer.currentTimeLocal, color: terminalGreen)
            InfoRow(label: "CURRENT TIME [EST]", value: timer.currentTimeEST, color: terminalGreen)
            InfoRow(label: "MARKET HOURS", value: "09:30 - 16:00", color: terminalGreen)
            InfoRow(label: "NEXT TRADING DAY", value: timer.nextTradingDay, color: terminalGreen)
        }
    }

    // MARK: - Quit Button

    private var quitButton: some View {
        Button(action: {
            NSApplication.shared.terminate(nil)
        }) {
            Text("QUIT")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(dimGreen)
        }
        .buttonStyle(.plain)
        .padding(.top, 16)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Info Row Component

struct InfoRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundColor(color)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(color)
        }
    }
}
