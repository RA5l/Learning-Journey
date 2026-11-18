import Foundation

enum GoalService {
    enum State {
        case active
        case completed
        case failed
    }

    static func endDate(of goal: LearningGoal, calendar: Calendar = .journey) -> Date {
        let start = calendar.startOfDay(for: goal.startDate)
        return calendar.date(byAdding: .day, value: goal.duration.days, to: start) ?? start
    }

    static func state(of goal: LearningGoal, days: [Day], now: Date = .now, calendar: Calendar = .journey) -> State {
        let end = endDate(of: goal, calendar: calendar)
        let summary = StreakService.summary(for: goal, days: days, until: min(now, end))

        if summary.hasBroken || summary.freezesUsed > goal.duration.freezeLimit {
            return .failed
        }

        let lastDay = calendar.date(byAdding: .day, value: -1, to: end) ?? end
        let loggedLastDay = days.contains { day in
            day.recordedAt >= goal.startDate && calendar.isDate(day.recordedAt, inSameDayAs: lastDay)
        }

        return now >= end || loggedLastDay ? .completed : .active
    }
}
