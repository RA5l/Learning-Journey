#if DEBUG
import Foundation

extension ProgressStore {
    enum PreviewScenario: String {
        case newGoal
        case loggedToday
        case frozenToday
        case allFreezesUsed
        case failed
        case completed
        case richHistory
    }

    static func preview(_ scenario: PreviewScenario) -> ProgressStore {
        let suite = "preview.\(scenario.rawValue)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let store = ProgressStore(defaults: defaults)
        let calendar = Calendar.journey
        let today = calendar.startOfDay(for: .now)
        let justNow = Date.now.addingTimeInterval(-60)

        func day(_ offset: Int, hour: Int = 20) -> Date {
            let date = calendar.date(byAdding: .day, value: offset, to: today)!
            return calendar.date(byAdding: .hour, value: hour, to: date)!
        }

        func weekGoal(startingDaysAgo days: Int) -> LearningGoal {
            LearningGoal(topic: "Swift", duration: .week, startDate: day(-days, hour: 8))
        }

        switch scenario {
        case .newGoal:
            store.setGoal(LearningGoal(topic: "Swift", duration: .week, startDate: Date.now.addingTimeInterval(-3600)))

        case .loggedToday:
            store.setGoal(weekGoal(startingDaysAgo: 3))
            for offset in -3...(-1) { store.record(.learned, at: day(offset)) }
            store.record(.learned, at: justNow)

        case .frozenToday:
            store.setGoal(weekGoal(startingDaysAgo: 3))
            for offset in -3...(-1) { store.record(.learned, at: day(offset)) }
            store.record(.frozen, at: justNow)

        case .allFreezesUsed:
            store.setGoal(weekGoal(startingDaysAgo: 3))
            store.record(.learned, at: day(-3))
            store.record(.frozen, at: day(-2))
            store.record(.frozen, at: day(-1))

        case .failed:
            store.setGoal(weekGoal(startingDaysAgo: 6))
            store.record(.learned, at: day(-6))
            store.record(.learned, at: day(-5))

        case .completed:
            store.setGoal(weekGoal(startingDaysAgo: 8))
            for offset in -8...(-2) { store.record(.learned, at: day(offset)) }

        case .richHistory:
            store.setGoal(LearningGoal(topic: "Swift", duration: .month, startDate: day(-10, hour: 8)))
            for offset in -100...(-1) {
                if offset < -10 && offset % 7 == 0 { continue }
                store.record(offset % 5 == 0 ? .frozen : .learned, at: day(offset))
            }
        }

        return store
    }
}
#endif
