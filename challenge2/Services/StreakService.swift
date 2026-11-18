import Foundation

enum StreakService {
    struct Summary {
        let streak: Int
        let freezesUsed: Int
        let lastActivity: Date
        let brokenAt: Date?

        var hasBroken: Bool { brokenAt != nil }

        static let empty = Summary(streak: 0, freezesUsed: 0, lastActivity: .distantPast, brokenAt: nil)
    }

    static let allowedGap: TimeInterval = 32 * 60 * 60

    static func summary(for goal: LearningGoal, days: [Day], until date: Date = .now) -> Summary {
        let records = days
            .filter { $0.recordedAt >= goal.startDate && $0.recordedAt <= date }
            .sorted { $0.recordedAt < $1.recordedAt }

        var streak = 0
        var freezesUsed = 0
        var lastActivity = goal.startDate
        var brokenAt: Date?

        for day in records {
            if day.recordedAt.timeIntervalSince(lastActivity) > allowedGap {
                streak = 0
                brokenAt = brokenAt ?? lastActivity.addingTimeInterval(allowedGap)
            }

            switch day.status {
            case .learned: streak += 1
            case .frozen: freezesUsed += 1
            }

            lastActivity = day.recordedAt
        }

        if date.timeIntervalSince(lastActivity) > allowedGap {
            streak = 0
            brokenAt = brokenAt ?? lastActivity.addingTimeInterval(allowedGap)
        }

        return Summary(streak: streak, freezesUsed: freezesUsed, lastActivity: lastActivity, brokenAt: brokenAt)
    }
}
