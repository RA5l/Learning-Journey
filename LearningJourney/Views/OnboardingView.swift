import SwiftUI

struct OnboardingView: View {
    @State private var viewModel: LearningGoalViewModel

    init(store: ProgressStore) {
        _viewModel = State(initialValue: LearningGoalViewModel(store: store, mode: .create))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "flame.fill")
                .font(.system(size: 44))
                .foregroundStyle(.learned)
                .accessibilityHidden(true)
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
                .padding(.bottom, 80)

            Text("Hello \(Text("Learner").bold())")
                .font(.largeTitle)

            Text("This app will help you learn everyday!")
                .foregroundStyle(.secondary)
                .padding(.bottom, 32)

            GoalFormView(topic: $viewModel.topic, duration: $viewModel.duration)

            Spacer()

            VStack(spacing: 10) {
                Button {
                    viewModel.submit()
                } label: {
                    Text("Start Learning").foregroundStyle(.white)
                }
                .buttonStyle(.glassProminent)
                .tint(.learned)
                .controlSize(.large)
                

                Text("You can edit your desire later")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
}

#Preview {
    OnboardingView(store: ProgressStore(defaults: UserDefaults(suiteName: "preview")!))
}
