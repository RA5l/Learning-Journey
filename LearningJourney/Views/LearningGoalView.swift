import SwiftUI

struct LearningGoalView: View {
    @State private var viewModel: LearningGoalViewModel
    @Environment(\.dismiss) private var dismiss

    init(store: ProgressStore, mode: LearningGoalViewModel.Mode) {
        _viewModel = State(initialValue: LearningGoalViewModel(store: store, mode: mode))
    }

    var body: some View {
        NavigationStack {
            VStack {
                GoalFormView(topic: $viewModel.topic, duration: $viewModel.duration)
                Spacer()
            }
            .padding()
            .navigationTitle("Learning Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.primary)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if viewModel.submit() { dismiss() }
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.learned)
                }
            }
        }
        .overlay {
            if viewModel.isShowingUpdateAlert {
                UpdateGoalDialog {
                    viewModel.isShowingUpdateAlert = false
                } onUpdate: {
                    viewModel.save()
                    dismiss()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isShowingUpdateAlert)
        .presentationDetents([.large])
    }
}

#Preview("Edit goal") {
    LearningGoalView(store: .preview(.loggedToday), mode: .edit)
}
