import Foundation
import Testing
@testable import challenge2

private let calendar = Calendar.journey

private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 9, _ minute: Int = 0) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

private func makeStore() -> ProgressStore {
    let suite = "tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    return ProgressStore(defaults: defaults)
}

private func makeGoal(_ duration: LearningGoal.GoalDuration = .week, start: Date = date(2026, 3, 1, 8)) -> LearningGoal {
    LearningGoal(topic: "Swift", duration: duration, startDate: start)
}

private final class TestClock {
    var now: Date
    init(_ now: Date) { self.now = now }
}

@MainActor
@Suite("Goal duration")
struct GoalDurationTests {
    @Test("Each duration has the right length and freeze limit", arguments: [
        (LearningGoal.GoalDuration.week, 7, 2),
        (LearningGoal.GoalDuration.month, 30, 8),
        (LearningGoal.GoalDuration.year, 365, 96)
    ])
    func lengthAndLimit(duration: LearningGoal.GoalDuration, days: Int, limit: Int) {
        #expect(duration.days == days)
        #expect(duration.freezeLimit == limit)
    }

    @Test("Calendar is Gregorian and weeks start on Sunday")
    func journeyCalendar() {
        #expect(calendar.identifier == .gregorian)
        #expect(calendar.firstWeekday == 1)
    }
}

@MainActor
@Suite("Streak")
struct StreakTests {
    @Test("No records yet means a streak of zero without a break")
    func empty() {
        let summary = StreakService.summary(for: makeGoal(), days: [], until: date(2026, 3, 1, 20))
        #expect(summary.streak == 0)
        #expect(!summary.hasBroken)
    }

    @Test("Learning on consecutive days grows the streak")
    func consecutiveDays() {
        let days = (1...3).map { Day(recordedAt: date(2026, 3, $0), status: .learned) }
        let summary = StreakService.summary(for: makeGoal(), days: days, until: date(2026, 3, 3, 20))
        #expect(summary.streak == 3)
        #expect(!summary.hasBroken)
    }

    @Test("A frozen day keeps the streak without increasing it")
    func frozenDay() {
        let days = [
            Day(recordedAt: date(2026, 3, 1), status: .learned),
            Day(recordedAt: date(2026, 3, 2), status: .frozen),
            Day(recordedAt: date(2026, 3, 3), status: .learned)
        ]
        let summary = StreakService.summary(for: makeGoal(), days: days, until: date(2026, 3, 3, 20))
        #expect(summary.streak == 2)
        #expect(summary.freezesUsed == 1)
        #expect(!summary.hasBroken)
    }

    @Test("A gap of exactly 32 hours does not break the streak")
    func exactlyThirtyTwoHours() {
        let first = date(2026, 3, 1, 9)
        let days = [
            Day(recordedAt: first, status: .learned),
            Day(recordedAt: first.addingTimeInterval(32 * 3600), status: .learned)
        ]
        let summary = StreakService.summary(for: makeGoal(), days: days, until: first.addingTimeInterval(33 * 3600))
        #expect(summary.streak == 2)
        #expect(!summary.hasBroken)
    }

    @Test("A gap longer than 32 hours breaks the streak at the 32nd hour")
    func moreThanThirtyTwoHours() {
        let first = date(2026, 3, 1, 9)
        let days = [
            Day(recordedAt: first, status: .learned),
            Day(recordedAt: first.addingTimeInterval(32 * 3600 + 60), status: .learned)
        ]
        let summary = StreakService.summary(for: makeGoal(), days: days, until: date(2026, 3, 3, 20))
        #expect(summary.hasBroken)
        #expect(summary.brokenAt == first.addingTimeInterval(32 * 3600))
    }

    @Test("Monday 9 AM then Tuesday 11 PM breaks the streak, as the spec says")
    func consecutiveDaysButTooFarApart() {
        let days = [
            Day(recordedAt: date(2026, 3, 2, 9), status: .learned),
            Day(recordedAt: date(2026, 3, 3, 23), status: .learned)
        ]
        let summary = StreakService.summary(for: makeGoal(start: date(2026, 3, 2, 8)), days: days, until: date(2026, 3, 3, 23, 30))
        #expect(summary.hasBroken)
    }

    @Test("Freezing resets the 32 hour timer")
    func freezeResetsTimer() {
        let days = [
            Day(recordedAt: date(2026, 3, 1, 9), status: .learned),
            Day(recordedAt: date(2026, 3, 2, 16), status: .frozen),
            Day(recordedAt: date(2026, 3, 3, 23), status: .learned)
        ]
        let summary = StreakService.summary(for: makeGoal(), days: days, until: date(2026, 3, 3, 23, 30))
        #expect(!summary.hasBroken)
        #expect(summary.streak == 2)
    }

    @Test("Doing nothing for more than 32 hours after the goal starts breaks it")
    func inactivityAfterStart() {
        let summary = StreakService.summary(for: makeGoal(), days: [], until: date(2026, 3, 2, 17))
        #expect(summary.hasBroken)
    }

    @Test("Records from before the current goal are ignored")
    func recordsBeforeGoal() {
        let days = [
            Day(recordedAt: date(2026, 2, 27), status: .learned),
            Day(recordedAt: date(2026, 2, 28), status: .frozen)
        ]
        let summary = StreakService.summary(for: makeGoal(), days: days, until: date(2026, 3, 1, 20))
        #expect(summary.streak == 0)
        #expect(summary.freezesUsed == 0)
    }
}

@MainActor
@Suite("Goal state")
struct GoalStateTests {
    @Test("The goal ends at midnight after its last day", arguments: [
        (LearningGoal.GoalDuration.week, 7),
        (LearningGoal.GoalDuration.month, 30),
        (LearningGoal.GoalDuration.year, 365)
    ])
    func endDate(duration: LearningGoal.GoalDuration, days: Int) {
        let start = date(2026, 3, 1, 8)
        let expected = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: start))
        #expect(GoalService.endDate(of: makeGoal(duration, start: start)) == expected)
    }

    @Test("A goal in progress without a break is active")
    func active() {
        let days = [Day(recordedAt: date(2026, 3, 1), status: .learned)]
        #expect(GoalService.state(of: makeGoal(), days: days, now: date(2026, 3, 1, 20)) == .active)
    }

    @Test("A break fails the goal immediately, before the duration ends")
    func failsImmediately() {
        let days = [Day(recordedAt: date(2026, 3, 1), status: .learned)]
        #expect(GoalService.state(of: makeGoal(), days: days, now: date(2026, 3, 3, 20)) == .failed)
    }

    @Test("Reaching the end of the week without a break completes the goal")
    func completed() {
        let days = (1...7).map { Day(recordedAt: date(2026, 3, $0), status: .learned) }
        #expect(GoalService.state(of: makeGoal(), days: days, now: date(2026, 3, 8, 0)) == .completed)
    }

    @Test("Logging on the last day completes the goal right away")
    func completedOnLastDay() {
        let days = (1...7).map { Day(recordedAt: date(2026, 3, $0), status: .learned) }
        #expect(GoalService.state(of: makeGoal(), days: days, now: date(2026, 3, 7, 10)) == .completed)
    }

    @Test("The goal is still active on the last day before logging")
    func activeOnLastDayBeforeLogging() {
        let days = (1...6).map { Day(recordedAt: date(2026, 3, $0), status: .learned) }
        #expect(GoalService.state(of: makeGoal(), days: days, now: date(2026, 3, 7, 10)) == .active)
    }

    @Test("Completed goals can include frozen days within the limit")
    func completedWithFreezes() {
        let statuses: [Day.DayStatus] = [.learned, .frozen, .learned, .learned, .frozen, .learned, .learned]
        let days = statuses.enumerated().map { Day(recordedAt: date(2026, 3, $0.offset + 1), status: $0.element) }
        #expect(GoalService.state(of: makeGoal(), days: days, now: date(2026, 3, 8, 0)) == .completed)
    }

    @Test("Using more freezes than allowed fails the goal")
    func tooManyFreezes() {
        let days = (1...3).map { Day(recordedAt: date(2026, 3, $0), status: .frozen) }
        #expect(GoalService.state(of: makeGoal(), days: days, now: date(2026, 3, 3, 20)) == .failed)
    }
}

@MainActor
@Suite("Progress store")
struct ProgressStoreTests {
    @Test("Goal and days survive an app restart")
    func persistence() {
        let suite = "tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = ProgressStore(defaults: defaults)
        store.setGoal(makeGoal())
        store.record(.learned, at: date(2026, 3, 1))

        let reopened = ProgressStore(defaults: defaults)
        #expect(reopened.goal == makeGoal())
        #expect(reopened.days.count == 1)
    }

    @Test("Logging the same status twice in a day keeps one record")
    func noDuplicates() {
        let store = makeStore()
        store.setGoal(makeGoal())
        store.record(.learned, at: date(2026, 3, 1, 9))
        store.record(.learned, at: date(2026, 3, 1, 15))
        #expect(store.days.count == 1)
    }

    @Test("Switching between learned and frozen in the same day replaces the record")
    func switchingStatus() {
        let store = makeStore()
        store.setGoal(makeGoal())

        store.record(.learned, at: date(2026, 3, 1, 9))
        store.record(.frozen, at: date(2026, 3, 1, 10))
        #expect(store.days.count == 1)
        #expect(store.status(on: date(2026, 3, 1)) == .frozen)

        store.record(.learned, at: date(2026, 3, 1, 22))
        #expect(store.days.count == 1)
        #expect(store.status(on: date(2026, 3, 1)) == .learned)
    }

    @Test("11:59 PM and 12:01 AM are two different days")
    func midnightBoundary() {
        let store = makeStore()
        store.setGoal(makeGoal())
        store.record(.learned, at: date(2026, 3, 1, 23, 59))
        store.record(.learned, at: date(2026, 3, 2, 0, 1))
        #expect(store.days.count == 2)
    }

    @Test("Updating the goal starts over but keeps the calendar history")
    func updatingGoal() {
        let store = makeStore()
        store.setGoal(makeGoal())
        store.record(.learned, at: date(2026, 3, 1, 9))

        let newGoal = makeGoal(.month, start: date(2026, 3, 1, 12))
        store.setGoal(newGoal)

        #expect(store.status(on: date(2026, 3, 1), since: newGoal.startDate) == nil)
        #expect(store.statusByDay()[calendar.startOfDay(for: date(2026, 3, 1))] == .learned)
        #expect(store.days.count == 1)
    }

    @Test("Logging again on the same day after updating the goal is allowed")
    func loggingAfterUpdate() {
        let store = makeStore()
        store.setGoal(makeGoal())
        store.record(.learned, at: date(2026, 3, 1, 9))
        store.setGoal(makeGoal(.month, start: date(2026, 3, 1, 12)))
        store.record(.learned, at: date(2026, 3, 1, 13))
        #expect(store.days.count == 2)
    }
}

@MainActor
@Suite("Activity screen")
struct ActivityViewModelTests {
    private func makeViewModel(goal: LearningGoal = makeGoal(), at now: Date) -> (ActivityViewModel, ProgressStore, TestClock) {
        let store = makeStore()
        store.setGoal(goal)
        let clock = TestClock(now)
        let viewModel = ActivityViewModel(store: store, clock: { clock.now })
        return (viewModel, store, clock)
    }

    @Test("A new day starts with both buttons available")
    func freshDay() {
        let (viewModel, _, _) = makeViewModel(at: date(2026, 3, 1, 10))
        #expect(viewModel.canLog)
        #expect(viewModel.canFreeze)
        #expect(viewModel.logButtonTitle == "Log as Learned")
        #expect(viewModel.freezeButtonTitle == "Freeze for a day")
        #expect(viewModel.freezeCaption == "0 out of 2 Freezes used")
    }

    @Test("After logging, the circle is disabled and freezing is still possible")
    func afterLogging() {
        let (viewModel, _, _) = makeViewModel(at: date(2026, 3, 1, 10))
        viewModel.logLearned()
        #expect(viewModel.todayStatus == .learned)
        #expect(!viewModel.canLog)
        #expect(viewModel.logButtonTitle == "Logged as Learned")
        #expect(viewModel.canFreeze)
        #expect(viewModel.streak == 1)
    }

    @Test("After freezing, the freeze button is disabled and logging is still possible")
    func afterFreezing() {
        let (viewModel, _, _) = makeViewModel(at: date(2026, 3, 1, 10))
        viewModel.freeze()
        #expect(viewModel.todayStatus == .frozen)
        #expect(!viewModel.isFreezeAvailable)
        #expect(viewModel.freezeButtonTitle == "Frozen for a day")
        #expect(viewModel.canLog)
        #expect(viewModel.freezeCaption == "1 out of 2 Freezes used")
    }

    @Test("Buttons come back at midnight")
    func midnight() {
        let (viewModel, _, clock) = makeViewModel(at: date(2026, 3, 1, 23))
        viewModel.logLearned()
        #expect(!viewModel.canLog)

        clock.now = date(2026, 3, 2, 0, 1)
        viewModel.refresh()
        #expect(viewModel.canLog)
        #expect(viewModel.todayStatus == nil)
    }

    @Test("When all freezes are used the freeze button turns gray")
    func freezeLimit() {
        let (viewModel, _, clock) = makeViewModel(at: date(2026, 3, 1, 10))
        viewModel.freeze()
        clock.now = date(2026, 3, 2, 10)
        viewModel.freeze()
        clock.now = date(2026, 3, 3, 10)
        viewModel.refresh()

        #expect(viewModel.freezesUsed == 2)
        #expect(!viewModel.isFreezeAvailable)
        #expect(!viewModel.canFreeze)
        #expect(viewModel.freezeButtonTitle == "Frozen for a day")
        #expect(viewModel.canLog)
    }

    @Test("A break shows the failure state with the numbers from before the break")
    func failure() {
        let (viewModel, _, clock) = makeViewModel(at: date(2026, 3, 1, 10))
        viewModel.logLearned()
        clock.now = date(2026, 3, 2, 10)
        viewModel.logLearned()

        clock.now = date(2026, 3, 5, 10)
        viewModel.refresh()

        #expect(viewModel.goalState == .failed)
        #expect(viewModel.streak == 2)
        #expect(!viewModel.canLog)
        #expect(!viewModel.canFreeze)
    }

    @Test("Finishing the week shows the success state")
    func success() {
        let (viewModel, _, clock) = makeViewModel(at: date(2026, 3, 1, 10))
        for day in 1...7 {
            clock.now = date(2026, 3, day, 10)
            viewModel.logLearned()
        }

        clock.now = date(2026, 3, 8, 0, 1)
        viewModel.refresh()

        #expect(viewModel.goalState == .completed)
        #expect(viewModel.streak == 7)
    }

    @Test("The next update is scheduled for the nearest upcoming event")
    func nextUpdate() {
        let (viewModel, _, _) = makeViewModel(at: date(2026, 3, 1, 10))
        viewModel.logLearned()
        #expect(viewModel.nextUpdate == date(2026, 3, 2, 0, 0))
    }
}

@MainActor
@Suite("Learning goal form")
struct LearningGoalViewModelTests {
    @Test("An empty or blank topic cannot be saved", arguments: ["", "   "])
    func blankTopic(topic: String) {
        let viewModel = LearningGoalViewModel(store: makeStore(), mode: .create)
        viewModel.topic = topic
        #expect(!viewModel.canSave)
        #expect(!viewModel.submit())
    }

    @Test("Creating a goal saves it right away")
    func create() {
        let store = makeStore()
        let viewModel = LearningGoalViewModel(store: store, mode: .create)
        viewModel.topic = "  Swift  "
        viewModel.duration = .month

        #expect(viewModel.submit())
        #expect(store.goal?.topic == "Swift")
        #expect(store.goal?.duration == .month)
    }

    @Test("Editing without changes closes without asking")
    func editWithoutChanges() {
        let store = makeStore()
        store.setGoal(makeGoal())
        let viewModel = LearningGoalViewModel(store: store, mode: .edit)

        #expect(viewModel.submit())
        #expect(!viewModel.isShowingUpdateAlert)
    }

    @Test("Editing with changes asks for confirmation before saving")
    func editWithChanges() {
        let store = makeStore()
        let original = makeGoal()
        store.setGoal(original)
        let viewModel = LearningGoalViewModel(store: store, mode: .edit)
        viewModel.duration = .year

        #expect(!viewModel.submit())
        #expect(viewModel.isShowingUpdateAlert)
        #expect(store.goal == original)

        viewModel.save()
        #expect(store.goal?.duration == .year)
    }
}

@MainActor
@Suite("Calendar screen")
struct ActivitiesViewModelTests {
    @Test("The calendar shows ten years")
    func tenYears() {
        let store = makeStore()
        store.setGoal(makeGoal(start: .now))
        let viewModel = ActivitiesViewModel(store: store)
        #expect(viewModel.months.count == 120)
        #expect(viewModel.currentMonthID != nil)
    }

    @Test("Months start under the right weekday", arguments: [
        (1, 4),
        (2, 0),
        (3, 0)
    ])
    func leadingBlanks(month: Int, blanks: Int) throws {
        let store = makeStore()
        store.setGoal(makeGoal(start: date(2026, 1, 5)))
        let viewModel = ActivitiesViewModel(store: store)
        let target = try #require(viewModel.months.first { $0.start == date(2026, month, 1, 0) })
        #expect(target.leadingBlanks == blanks)
    }

    @Test("February 2026 has 28 days")
    func monthLength() throws {
        let store = makeStore()
        store.setGoal(makeGoal(start: date(2026, 1, 5)))
        let viewModel = ActivitiesViewModel(store: store)
        let february = try #require(viewModel.months.first { $0.start == date(2026, 2, 1, 0) })
        #expect(february.days.count == 28)
    }
}
