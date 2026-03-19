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
    private var nyCalendar: Calendar

    // NYSE Regular Trading Hours (Eastern Time)
    private let marketOpenHour = 9
    private let marketOpenMinute = 30
    private let marketCloseHour = 16
    private let marketCloseMinute = 0

    // Precomputed constants (in seconds)
    private let openTotalSeconds: Int
    private let closeTotalSeconds: Int

    // Cached DateFormatters (expensive to create)
    private static let estFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.timeZone = TimeZone(identifier: "America/New_York")!
        fmt.dateFormat = "HH:mm:ss"
        return fmt
    }()

    private static let localFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        return fmt
    }()

    private static let dayNameFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.timeZone = TimeZone(identifier: "America/New_York")!
        fmt.dateFormat = "EEEE"
        return fmt
    }()

    // Holiday cache: store holidays as (month, day) pairs for a given year
    private var cachedHolidayYear: Int = 0
    private var cachedHolidays: Set<Int> = [] // Encoded as month * 100 + day

    init() {
        nyTimeZone = TimeZone(identifier: "America/New_York")!
        nyCalendar = Calendar(identifier: .gregorian)
        nyCalendar.timeZone = nyTimeZone
        openTotalSeconds = 9 * 3600 + 30 * 60
        closeTotalSeconds = 16 * 3600
        localTimeZoneAbbr = TimeZone.current.abbreviation() ?? "LOCAL"
        update()
    }

    func update() {
        update(for: Date())
    }

    func update(for date: Date) {
        updateTimes(date)
        updateMarketStatus(date)
    }

    // MARK: - Time Display

    private func updateTimes(_ now: Date) {
        currentTimeEST = MarketTimer.estFormatter.string(from: now)
        currentTimeLocal = MarketTimer.localFormatter.string(from: now)

        // Only update timezone abbreviation if it actually changed (DST transitions)
        let currentAbbr = TimeZone.current.abbreviation() ?? "LOCAL"
        if currentAbbr != localTimeZoneAbbr {
            localTimeZoneAbbr = currentAbbr
        }
    }

    // MARK: - Market Status Logic

    private func updateMarketStatus(_ now: Date) {
        let weekday = nyCalendar.component(.weekday, from: now)
        let hour = nyCalendar.component(.hour, from: now)
        let minute = nyCalendar.component(.minute, from: now)
        let second = nyCalendar.component(.second, from: now)

        let currentTotalSeconds = hour * 3600 + minute * 60 + second

        let isWeekday = weekday >= 2 && weekday <= 6
        let isHoliday = isMarketHoliday(now)
        let isTradingDay = isWeekday && !isHoliday
        let isDuringHours = currentTotalSeconds >= openTotalSeconds && currentTotalSeconds < closeTotalSeconds

        isMarketOpen = isTradingDay && isDuringHours

        if isMarketOpen {
            statusText = "MARKET OPEN"
            countdownLabel = "TIME UNTIL MARKET CLOSE"
            nextTradingDay = "TODAY"

            let remaining = closeTotalSeconds - currentTotalSeconds
            let formatted = formatCountdown(max(0, remaining))
            countdownString = formatted
            menuBarCountdown = formatted
        } else {
            statusText = "MARKET CLOSED"
            countdownLabel = "TIME UNTIL MARKET OPEN"

            let nextOpen = findNextMarketOpen(from: now)
            let remaining = Int(nextOpen.timeIntervalSince(now))
            let formatted = formatCountdown(max(0, remaining))
            countdownString = formatted
            menuBarCountdown = formatted
            nextTradingDay = getNextTradingDayLabel(from: now, nextOpen: nextOpen)
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

    private func findNextMarketOpen(from date: Date) -> Date {
        let hour = nyCalendar.component(.hour, from: date)
        let minute = nyCalendar.component(.minute, from: date)
        let currentMinutes = hour * 60 + minute
        let weekday = nyCalendar.component(.weekday, from: date)
        let isWeekday = weekday >= 2 && weekday <= 6

        // If it's a trading day and before market open, return today's open
        if isWeekday && !isMarketHoliday(date) && currentMinutes < marketOpenHour * 60 + marketOpenMinute {
            var components = nyCalendar.dateComponents([.year, .month, .day], from: date)
            components.hour = marketOpenHour
            components.minute = marketOpenMinute
            components.second = 0
            components.timeZone = nyTimeZone
            return nyCalendar.date(from: components) ?? date
        }

        // Otherwise, find the next trading day
        var checkDate = nyCalendar.startOfDay(for: date)
        for _ in 0..<14 {
            checkDate = nyCalendar.date(byAdding: .day, value: 1, to: checkDate)!
            let wd = nyCalendar.component(.weekday, from: checkDate)
            if wd >= 2 && wd <= 6 && !isMarketHoliday(checkDate) {
                var components = nyCalendar.dateComponents([.year, .month, .day], from: checkDate)
                components.hour = marketOpenHour
                components.minute = marketOpenMinute
                components.second = 0
                components.timeZone = nyTimeZone
                return nyCalendar.date(from: components) ?? checkDate
            }
        }

        return date
    }

    // MARK: - Next Trading Day Label

    private func getNextTradingDayLabel(from now: Date, nextOpen: Date) -> String {
        let nowDay = nyCalendar.startOfDay(for: now)
        let openDay = nyCalendar.startOfDay(for: nextOpen)
        let diff = nyCalendar.dateComponents([.day], from: nowDay, to: openDay).day ?? 0

        if diff == 0 {
            return "TODAY"
        } else if diff == 1 {
            return "TOMORROW"
        } else {
            return MarketTimer.dayNameFormatter.string(from: nextOpen).uppercased()
        }
    }

    // MARK: - US Market Holiday Calendar (Cached)

    private func isMarketHoliday(_ date: Date) -> Bool {
        let year = nyCalendar.component(.year, from: date)

        // Rebuild holiday cache when year changes
        if year != cachedHolidayYear {
            rebuildHolidayCache(for: year)
        }

        let month = nyCalendar.component(.month, from: date)
        let day = nyCalendar.component(.day, from: date)
        return cachedHolidays.contains(month * 100 + day)
    }

    private func rebuildHolidayCache(for year: Int) {
        cachedHolidayYear = year
        cachedHolidays = []

        // Helper to add a holiday with observed-date rules
        func addFixedHoliday(month: Int, day: Int) {
            // Determine what weekday this date falls on
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            components.timeZone = nyTimeZone
            if let date = nyCalendar.date(from: components) {
                let wd = nyCalendar.component(.weekday, from: date)
                if wd >= 2 && wd <= 6 {
                    // Weekday: observe on actual date
                    cachedHolidays.insert(month * 100 + day)
                } else if wd == 1 {
                    // Sunday: observe on Monday
                    let nextDay = day + 1
                    let nextMonth = month
                    cachedHolidays.insert(nextMonth * 100 + nextDay)
                } else {
                    // Saturday: observe on Friday
                    let prevDay = day - 1
                    // Handle month boundary for New Year's (Jan 1 on Saturday -> Dec 31)
                    if month == 1 && day == 1 {
                        cachedHolidays.insert(12 * 100 + 31)
                    } else {
                        cachedHolidays.insert(month * 100 + prevDay)
                    }
                }
            }
        }

        // Helper to find nth weekday of a month
        func nthWeekday(_ n: Int, weekday: Int, month: Int) -> Int? {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            components.timeZone = nyTimeZone
            guard let firstOfMonth = nyCalendar.date(from: components) else { return nil }
            let firstWeekday = nyCalendar.component(.weekday, from: firstOfMonth)
            var day = 1 + (weekday - firstWeekday + 7) % 7
            day += (n - 1) * 7
            return day
        }

        // Helper to find last weekday of a month
        func lastWeekday(_ weekday: Int, month: Int) -> Int? {
            var components = DateComponents()
            components.year = year
            components.month = month + 1
            components.day = 0 // Last day of previous month
            components.timeZone = nyTimeZone
            guard let lastDay = nyCalendar.date(from: components) else { return nil }
            let lastDayNum = nyCalendar.component(.day, from: lastDay)
            let lastDayWeekday = nyCalendar.component(.weekday, from: lastDay)
            let diff = (lastDayWeekday - weekday + 7) % 7
            return lastDayNum - diff
        }

        // --- New Year's Day (January 1) ---
        addFixedHoliday(month: 1, day: 1)

        // --- Martin Luther King Jr. Day (3rd Monday in January) ---
        if let day = nthWeekday(3, weekday: 2, month: 1) {
            cachedHolidays.insert(1 * 100 + day)
        }

        // --- Presidents' Day (3rd Monday in February) ---
        if let day = nthWeekday(3, weekday: 2, month: 2) {
            cachedHolidays.insert(2 * 100 + day)
        }

        // --- Good Friday ---
        addGoodFriday(year: year)

        // --- Memorial Day (Last Monday in May) ---
        if let day = lastWeekday(2, month: 5) {
            cachedHolidays.insert(5 * 100 + day)
        }

        // --- Juneteenth (June 19) ---
        addFixedHoliday(month: 6, day: 19)

        // --- Independence Day (July 4) ---
        addFixedHoliday(month: 7, day: 4)

        // --- Labor Day (1st Monday in September) ---
        if let day = nthWeekday(1, weekday: 2, month: 9) {
            cachedHolidays.insert(9 * 100 + day)
        }

        // --- Thanksgiving Day (4th Thursday in November) ---
        if let day = nthWeekday(4, weekday: 5, month: 11) {
            cachedHolidays.insert(11 * 100 + day)
        }

        // --- Christmas Day (December 25) ---
        addFixedHoliday(month: 12, day: 25)

        // Also cache next year's New Year observed date (in case Dec 31 is a Friday)
        var nextYearComponents = DateComponents()
        nextYearComponents.year = year + 1
        nextYearComponents.month = 1
        nextYearComponents.day = 1
        nextYearComponents.timeZone = nyTimeZone
        if let nextNewYear = nyCalendar.date(from: nextYearComponents) {
            let wd = nyCalendar.component(.weekday, from: nextNewYear)
            if wd == 7 { // Saturday -> observed Friday Dec 31
                cachedHolidays.insert(12 * 100 + 31)
            }
        }
    }

    // MARK: - Easter / Good Friday Calculation (Anonymous Gregorian Algorithm)

    private func addGoodFriday(year: Int) {
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

        if let easter = nyCalendar.date(from: easterComponents),
           let goodFriday = nyCalendar.date(byAdding: .day, value: -2, to: easter) {
            let gfMonth = nyCalendar.component(.month, from: goodFriday)
            let gfDay = nyCalendar.component(.day, from: goodFriday)
            cachedHolidays.insert(gfMonth * 100 + gfDay)
        }
    }
}
