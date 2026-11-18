import Foundation
import Observation

@Observable
final class LearningGoalViewModel {
    enum Mode {
        case create
        case edit
    }

    var topic: String
    var duration: LearningGoal.GoalDuration
    var isShowingUpdateAlert = false

    let mode: Mode
    private let store: ProgressStore

    init(store: ProgressStore, mode: Mode) {
        self.store = store
        self.mode = mode
        topic = store.goal?.topic ?? ""
        duration = store.goal?.duration ?? .week
    }

    private var trimmedTopic: String {
        topic.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool { !trimmedTopic.isEmpty }

    private var hasChanges: Bool {
        store.goal?.topic != trimmedTopic || store.goal?.duration != duration
    }

    @discardableResult
    func submit() -> Bool {
        guard canSave else { return false }

        switch mode {
        case .create:
            save()
            return true
        case .edit:
            guard hasChanges else { return true }
            isShowingUpdateAlert = true
            return false
        }
    }

    func save() {
        store.setGoal(LearningGoal(topic: trimmedTopic, duration: duration))
    }
}
