import Foundation

struct LearningGoal: Codable, Equatable {
    var topic: String
    var duration: GoalDuration
    var startDate: Date = .now

    enum GoalDuration: String, CaseIterable, Codable {
        case week = "Week"
        case month = "Month"
        case year = "Year"

        var days: Int {
            switch self {
            case .week: 7
            case .month: 30
            case .year: 365
            }
        }

        var freezeLimit: Int {
            switch self {
            case .week: 2
            case .month: 8
            case .year: 96
            }
        }
    }
}
