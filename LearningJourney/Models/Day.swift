import Foundation

struct Day: Codable, Identifiable {
    var id = UUID()
    var recordedAt: Date = .now
    var status: DayStatus

    enum DayStatus: String, Codable {
        case learned
        case frozen
    }
}
