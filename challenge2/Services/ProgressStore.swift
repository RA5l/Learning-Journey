import Foundation
import Observation

@Observable
final class ProgressStore {
    private(set) var goal: LearningGoal? = nil
    private(set) var days: [Day] = []

    private let defaults: UserDefaults
    private static let goalKey = "learningGoal"
    private static let daysKey = "days"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        goal = load(LearningGoal.self, forKey: Self.goalKey)
        days = load([Day].self, forKey: Self.daysKey) ?? []
    }

    func setGoal(_ newGoal: LearningGoal) {
        goal = newGoal
        save(newGoal, forKey: Self.goalKey)
    }

    func record(_ status: Day.DayStatus, at date: Date = .now, calendar: Calendar = .journey) {
        let goalStart = goal?.startDate ?? .distantPast
        let existingIndex = days.lastIndex { day in
            day.recordedAt >= goalStart && calendar.isDate(day.recordedAt, inSameDayAs: date)
        }

        if let existingIndex {
            guard days[existingIndex].status != status else { return }
            days[existingIndex].status = status
            days[existingIndex].recordedAt = date
        } else {
            days.append(Day(recordedAt: date, status: status))
        }

        save(days, forKey: Self.daysKey)
    }

    func records(since start: Date?) -> [Day] {
        guard let start else { return days }
        return days.filter { $0.recordedAt >= start }
    }

    func status(on date: Date, since start: Date? = nil, calendar: Calendar = .journey) -> Day.DayStatus? {
        records(since: start).last { calendar.isDate($0.recordedAt, inSameDayAs: date) }?.status
    }

    func statusByDay(since start: Date? = nil, calendar: Calendar = .journey) -> [Date: Day.DayStatus] {
        Dictionary(
            records(since: start).map { (calendar.startOfDay(for: $0.recordedAt), $0.status) },
            uniquingKeysWith: { _, latest in latest }
        )
    }

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
