import SwiftUI

enum GoalSheet: String, Identifiable {
    case edit
    case new

    var id: String { rawValue }
}

struct ActivityView: View {
    let store: ProgressStore
    @State private var viewModel: ActivityViewModel
    @State private var goalSheet: GoalSheet?
    @Environment(\.scenePhase) private var scenePhase

    init(store: ProgressStore) {
        self.store = store
        _viewModel = State(initialValue: ActivityViewModel(store: store))
    }

    var body: some View {
        VStack(spacing: 20) {
            header

            WeekStripView(symbols: viewModel.weekdaySymbols, days: viewModel.weekDays)

            HStack(spacing: 12) {
                StatCardView(systemImage: "flame.fill", tint: .learned, count: viewModel.streak, label: "Learned")
                StatCardView(systemImage: "snowflake", tint: .frozen, count: viewModel.freezesUsed, label: "Frozen")
            }

            Spacer()

            switch viewModel.goalState {
            case .active:
                actions
            case .completed:
                GoalEndView(didSucceed: true) { goalSheet = .new }
            case .failed:
                GoalEndView(didSucceed: false) { goalSheet = .new }
            }

            Spacer()
        }
        .padding(.horizontal)
        .animation(.snappy, value: viewModel.todayStatus)
        .animation(.snappy, value: viewModel.goalState)
        .sensoryFeedback(trigger: viewModel.todayStatus) { _, newStatus in
            newStatus == nil ? nil : .success
        }
        .ignoresSafeArea(.keyboard)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: String.self) { _ in
            ActivitiesView(store: store)
        }
        .sheet(item: $goalSheet) { sheet in
            LearningGoalView(store: store, mode: sheet == .edit ? .edit : .create)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.refresh() }
        }
        .task(id: viewModel.nextUpdate) {
            let delay = viewModel.nextUpdate.timeIntervalSinceNow
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            guard !Task.isCancelled else { return }
            viewModel.refresh()
        }
        .onAppear { viewModel.refresh() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Activity")
                    .font(.largeTitle.bold())
                Text(viewModel.todayTitle)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                NavigationLink(value: "calendar") {
                    circleIcon("calendar")
                }
                .accessibilityLabel("Calendar")

                Button {
                    goalSheet = .edit
                } label: {
                    circleIcon("pencil.and.outline")
                }
                .accessibilityLabel("Edit learning goal")
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .foregroundStyle(.primary)
        }
        .padding(.top, 8)
    }

    private func circleIcon(_ systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.title3)
            .frame(width: 32, height: 32)
    }

    private var actions: some View {
        VStack(spacing: 32) {
            logButton

            VStack(spacing: 10) {
                freezeButton

                Text(viewModel.freezeCaption)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var logButton: some View {
        let label = Text(viewModel.logButtonTitle)
            .font(.title2.bold())
            .frame(width: 250, height: 250)

        if viewModel.canLog {
            Button(action: viewModel.logLearned) {
                label.foregroundStyle(.white)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
            .tint(.learned)
        } else {
            Button(action: {}) {
                label.foregroundStyle(.secondary)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var freezeButton: some View {
        let label = Text(viewModel.freezeButtonTitle)
            .font(.headline)
            .frame(width: 250)

        if viewModel.isFreezeAvailable {
            Button(action: viewModel.freeze) {
                label.foregroundStyle(.white)
            }
            .buttonStyle(.glassProminent)
            .tint(.frozen)
            .allowsHitTesting(viewModel.canFreeze)
        } else {
            Button(action: {}) {
                label.foregroundStyle(.secondary)
            }
            .buttonStyle(.glass)
            .allowsHitTesting(false)
        }
    }
}

#Preview("New goal") {
    NavigationStack { ActivityView(store: .preview(.newGoal)) }
}

#Preview("Logged today") {
    NavigationStack { ActivityView(store: .preview(.loggedToday)) }
}

#Preview("Frozen today") {
    NavigationStack { ActivityView(store: .preview(.frozenToday)) }
}

#Preview("All freezes used") {
    NavigationStack { ActivityView(store: .preview(.allFreezesUsed)) }
}

#Preview("Failed") {
    NavigationStack { ActivityView(store: .preview(.failed)) }
}

#Preview("Completed") {
    NavigationStack { ActivityView(store: .preview(.completed)) }
}
