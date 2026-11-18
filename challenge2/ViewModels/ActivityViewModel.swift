import Foundation
import Observation

@Observable
final class ActivityViewModel {
    private let store: ProgressStore
    private let calendar: Calendar
    private let clock: () -> Date
    private(set) var now: Date

    init(store: ProgressStore, calendar: Calendar = .journey, clock: @escaping () -> Date = { .now }) {
        self.store = store
        self.calendar = calendar
        self.clock = clock
        now = clock()
    }

    private static let titleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .journey
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter
    }()

    private var summary: StreakService.Summary {
        guard let goal = store.goal else { return .empty }
        let current = StreakService.summary(for: goal, days: store.days, until: now)

        guard let brokenAt = current.brokenAt else { return current }
        return StreakService.summary(for: goal, days: store.days, until: brokenAt)
    }

    var todayTitle: String { Self.titleFormatter.string(from: now) }
    var streak: Int { summary.streak }
    var freezesUsed: Int { summary.freezesUsed }
    var freezeLimit: Int { store.goal?.duration.freezeLimit ?? 0 }
    var todayStatus: Day.DayStatus? { store.status(on: now, since: store.goal?.startDate, calendar: calendar) }

    var goalState: GoalService.State {
        guard let goal = store.goal else { return .active }
        return GoalService.state(of: goal, days: store.days, now: now, calendar: calendar)
    }

    var canLog: Bool { goalState == .active && todayStatus != .learned }
    var isFreezeAvailable: Bool { todayStatus != .frozen && freezesUsed < freezeLimit }
    var canFreeze: Bool { goalState == .active && isFreezeAvailable }

    var logButtonTitle: String {
        todayStatus == .learned ? "Logged as Learned" : "Log as Learned"
    }

    var freezeButtonTitle: String {
        isFreezeAvailable ? "Freeze for a day" : "Frozen for a day"
    }

    var freezeCaption: String { "\(freezesUsed) out of \(freezeLimit) Freezes used" }

    var weekdaySymbols: [String] { calendar.veryShortStandaloneWeekdaySymbols }

    var weekDays: [CalendarDay] {
        guard let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        let statuses = store.statusByDay(since: store.goal?.startDate, calendar: calendar)
        return (0..<7)
            .compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
            .map { CalendarDay(date: $0, statuses: statuses, now: now, calendar: calendar) }
    }

    var nextUpdate: Date {
        var candidates: [Date] = []

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) {
            candidates.append(tomorrow)
        }

        if let goal = store.goal {
            candidates.append(summary.lastActivity.addingTimeInterval(StreakService.allowedGap + 1))
            candidates.append(GoalService.endDate(of: goal, calendar: calendar))
        }

        return candidates.filter { $0 > now }.min() ?? now.addingTimeInterval(3600)
    }

    func refresh() {
        now = clock()
    }

    func logLearned() {
        refresh()
        guard canLog else { return }
        store.record(.learned, at: now)
    }

    func freeze() {
        refresh()
        guard canFreeze else { return }
        store.record(.frozen, at: now)
    }
}
