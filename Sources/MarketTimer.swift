import Foundation
import Combine

class MarketTimer: ObservableObject {
    @Published var isMarketOpen: Bool = false
    @Published var countdownString: String = "00:00:00"
    @Published var menuBarCountdown: String = "00:00:00"
    @Published var currentTimeEST: String = "00:00:00"
    @Published var currentTimeLocal: String = "00:00:00"
    @Published var localTimeZoneAbbr: String = ""
    @Published var statusText: String = "MARKET CLOSED"
    @Published var countdownLabel: String = "TIME UNTIL MARKET OPEN"
    @Published var nextTradingDay: String = "TODAY"

    private let nyTimeZone: TimeZone

    // NYSE Regular Trading Hours (Eastern Time)
    private let marketOpenHour = 9
    private let marketOpenMinute = 30
    private let marketCloseHour = 16
    private let marketCloseMinute = 0

    init() {
        nyTimeZone = TimeZone(identifier: "America/New_York")!
        localTimeZoneAbbr = TimeZone.current.abbreviation() ?? "LOCAL"
        update()
    }

    func update() {
        let now = Date()
        updateTimes(now)
        updateMarketStatus(now)
    }

    // MARK: - Time Display

    private func updateTimes(_ now: Date) {
        let estFmt = DateFormatter()
        estFmt.timeZone = nyTimeZone
        estFmt.dateFormat = "HH:mm:ss"
        currentTimeEST = estFmt.string(from: now)

        let localFmt = DateFormatter()
        localFmt.dateFormat = "HH:mm:ss"
        currentTimeLocal = localFmt.string(from: now)

        localTimeZoneAbbr = TimeZone.current.abbreviation() ?? "LOCAL"
    }

    // MARK: - Market Status Logic

    private func updateMarketStatus(_ now: Date) {
        var nyCal = Calendar(identifier: .gregorian)
        nyCal.timeZone = nyTimeZone

        let weekday = nyCal.component(.weekday, from: now)
        let hour = nyCal.component(.hour, from: now)
        let minute = nyCal.component(.minute, from: now)
        let second = nyCal.component(.second, from: now)

        let currentTotalSeconds = hour * 3600 + minute * 60 + second
        let openTotalSeconds = marketOpenHour * 3600 + marketOpenMinute * 60
        let closeTotalSeconds = marketCloseHour * 3600 + marketCloseMinute * 60

        let isWeekday = weekday >= 2 && weekday <= 6
        let isHoliday = isMarketHoliday(now, calendar: nyCal)
        let isTradingDay = isWeekday && !isHoliday
        let isDuringHours = currentTotalSeconds >= openTotalSeconds && currentTotalSeconds < closeTotalSeconds

        isMarketOpen = isTradingDay && isDuringHours

        if isMarketOpen {
            statusText = "MARKET OPEN"
            countdownLabel = "TIME UNTIL MARKET CLOSE"
            nextTradingDay = "TODAY"

            let remaining = closeTotalSeconds - currentTotalSeconds
            countdownString = formatCountdown(max(0, remaining))
            menuBarCountdown = formatCountdown(max(0, remaining))
        } else {
            statusText = "MARKET CLOSED"
            countdownLabel = "TIME UNTIL MARKET OPEN"

            let nextOpen = findNextMarketOpen(from: now, calendar: nyCal)
            let remaining = Int(nextOpen.timeIntervalSince(now))
            countdownString = formatCountdown(max(0, remaining))
            menuBarCountdown = formatCountdown(max(0, remaining))
            nextTradingDay = getNextTradingDayLabel(from: now, nextOpen: nextOpen, calendar: nyCal)
        }
    }

    // MARK: - Countdown Formatting

    private func formatCountdown(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Next Market Open Calculation

    private func findNextMarketOpen(from date: Date, calendar: Calendar) -> Date {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentMinutes = hour * 60 + minute
        let weekday = calendar.component(.weekday, from: date)
        let isWeekday = weekday >= 2 && weekday <= 6

        // If it's a trading day and before market open, return today's open
        if isWeekday && !isMarketHoliday(date, calendar: calendar) && currentMinutes < marketOpenHour * 60 + marketOpenMinute {
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = marketOpenHour
            components.minute = marketOpenMinute
            components.second = 0
            components.timeZone = nyTimeZone
            return calendar.date(from: components) ?? date
        }

        // Otherwise, find the next trading day
        var checkDate = calendar.startOfDay(for: date)
        for _ in 0..<14 {
            checkDate = calendar.date(byAdding: .day, value: 1, to: checkDate)!
            let wd = calendar.component(.weekday, from: checkDate)
            if wd >= 2 && wd <= 6 && !isMarketHoliday(checkDate, calendar: calendar) {
                var components = calendar.dateComponents([.year, .month, .day], from: checkDate)
                components.hour = marketOpenHour
                components.minute = marketOpenMinute
                components.second = 0
                components.timeZone = nyTimeZone
                return calendar.date(from: components) ?? checkDate
            }
        }

        return date
    }

    // MARK: - Next Trading Day Label

    private func getNextTradingDayLabel(from now: Date, nextOpen: Date, calendar: Calendar) -> String {
        let nowDay = calendar.startOfDay(for: now)
        let openDay = calendar.startOfDay(for: nextOpen)
        let diff = calendar.dateComponents([.day], from: nowDay, to: openDay).day ?? 0

        if diff == 0 {
            return "TODAY"
        } else if diff == 1 {
            return "TOMORROW"
        } else {
            let formatter = DateFormatter()
            formatter.timeZone = nyTimeZone
            formatter.dateFormat = "EEEE"
            return formatter.string(from: nextOpen).uppercased()
        }
    }

    // MARK: - US Market Holiday Calendar

    private func isMarketHoliday(_ date: Date, calendar: Calendar) -> Bool {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let weekday = calendar.component(.weekday, from: date) // 1=Sun, 2=Mon, ... 6=Fri, 7=Sat

        // --- New Year's Day (January 1) ---
        if month == 1 && day == 1 && weekday >= 2 && weekday <= 6 { return true }
        if month == 1 && day == 2 && weekday == 2 { return true }  // Observed Monday (Jan 1 was Sunday)
        if month == 12 && day == 31 && weekday == 6 { return true } // Observed Friday (Jan 1 next year is Saturday)

        // --- Martin Luther King Jr. Day (3rd Monday in January) ---
        if month == 1 && weekday == 2 && day >= 15 && day <= 21 { return true }

        // --- Presidents' Day (3rd Monday in February) ---
        if month == 2 && weekday == 2 && day >= 15 && day <= 21 { return true }

        // --- Good Friday (Friday before Easter Sunday) ---
        if isGoodFriday(date, year: year, calendar: calendar) { return true }

        // --- Memorial Day (Last Monday in May) ---
        if month == 5 && weekday == 2 {
            if let nextWeek = calendar.date(byAdding: .day, value: 7, to: date) {
                if calendar.component(.month, from: nextWeek) != 5 { return true }
            }
        }

        // --- Juneteenth National Independence Day (June 19) ---
        if month == 6 && day == 19 && weekday >= 2 && weekday <= 6 { return true }
        if month == 6 && day == 20 && weekday == 2 { return true }  // Observed Monday
        if month == 6 && day == 18 && weekday == 6 { return true }  // Observed Friday

        // --- Independence Day (July 4) ---
        if month == 7 && day == 4 && weekday >= 2 && weekday <= 6 { return true }
        if month == 7 && day == 5 && weekday == 2 { return true }  // Observed Monday
        if month == 7 && day == 3 && weekday == 6 { return true }  // Observed Friday

        // --- Labor Day (1st Monday in September) ---
        if month == 9 && weekday == 2 && day >= 1 && day <= 7 { return true }

        // --- Thanksgiving Day (4th Thursday in November) ---
        if month == 11 && weekday == 5 && day >= 22 && day <= 28 { return true }

        // --- Christmas Day (December 25) ---
        if month == 12 && day == 25 && weekday >= 2 && weekday <= 6 { return true }
        if month == 12 && day == 26 && weekday == 2 { return true }  // Observed Monday
        if month == 12 && day == 24 && weekday == 6 { return true }  // Observed Friday

        return false
    }

    // MARK: - Easter / Good Friday Calculation (Anonymous Gregorian Algorithm)

    private func isGoodFriday(_ date: Date, year: Int, calendar: Calendar) -> Bool {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let easterMonth = (h + l - 7 * m + 114) / 31
        let easterDay = ((h + l - 7 * m + 114) % 31) + 1

        var easterComponents = DateComponents()
        easterComponents.year = year
        easterComponents.month = easterMonth
        easterComponents.day = easterDay
        easterComponents.timeZone = nyTimeZone

        if let easter = calendar.date(from: easterComponents),
           let goodFriday = calendar.date(byAdding: .day, value: -2, to: easter) {
            let gfMonth = calendar.component(.month, from: goodFriday)
            let gfDay = calendar.component(.day, from: goodFriday)
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            return month == gfMonth && day == gfDay
        }

        return false
    }
}
