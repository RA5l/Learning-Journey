import Foundation
import Observation

@Observable
final class ActivitiesViewModel {
    struct Month: Identifiable {
        let start: Date
        let title: String
        let leadingBlanks: Int
        let days: [CalendarDay]

        var id: Date { start }
    }

    static let visibleYears = 10

    private let store: ProgressStore
    private let calendar: Calendar
    private(set) var months: [Month] = []
    private(set) var currentMonthID: Date?

    init(store: ProgressStore, calendar: Calendar = .journey) {
        self.store = store
        self.calendar = calendar
        load()
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .journey
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    var weekdaySymbols: [String] {
        calendar.shortStandaloneWeekdaySymbols.map { $0.uppercased() }
    }

    func load() {
        let now = Date.now
        let currentYear = calendar.component(.year, from: now)
        let goalStart = store.goal.map { [$0.startDate] } ?? []
        let firstYear = (goalStart + store.days.map(\.recordedAt)).min()
            .map { calendar.component(.year, from: $0) } ?? currentYear
        let startYear = max(firstYear, currentYear - Self.visibleYears + 1)

        guard let windowStart = calendar.date(from: DateComponents(year: startYear, month: 1, day: 1)) else { return }

        let statuses = store.statusByDay(calendar: calendar)
        months = (0..<Self.visibleYears * 12)
            .compactMap { calendar.date(byAdding: .month, value: $0, to: windowStart) }
            .map { makeMonth(startingAt: $0, statuses: statuses, now: now) }
        currentMonthID = calendar.dateInterval(of: .month, for: now)?.start
    }

    private func makeMonth(startingAt start: Date, statuses: [Date: Day.DayStatus], now: Date) -> Month {
        let dayCount = calendar.range(of: .day, in: .month, for: start)?.count ?? 0
        let weekday = calendar.component(.weekday, from: start)
        let leadingBlanks = (weekday - calendar.firstWeekday + 7) % 7

        let days = (0..<dayCount)
            .compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
            .map { CalendarDay(date: $0, statuses: statuses, now: now, calendar: calendar) }

        return Month(
            start: start,
            title: Self.monthFormatter.string(from: start),
            leadingBlanks: leadingBlanks,
            days: days
        )
    }
}
