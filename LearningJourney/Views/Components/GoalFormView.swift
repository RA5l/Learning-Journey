import SwiftUI

struct GoalFormView: View {
    @Binding var topic: String
    @Binding var duration: LearningGoal.GoalDuration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("I want to learn")

            TextField("Swift", text: $topic)
                .autocorrectionDisabled()
                .submitLabel(.done)

            Divider()

            Text("I want to learn it in a")
                .padding(.top, 16)

            HStack(spacing: 8) {
                ForEach(LearningGoal.GoalDuration.allCases, id: \.self) { option in
                    if option == duration {
                        Button { duration = option } label: {
                            Text(option.rawValue).foregroundStyle(.white)
                        }
                            .buttonStyle(.glassProminent)
                            .tint(.learned)
                    } else {
                        Button(option.rawValue) { duration = option }
                            .buttonStyle(.glass)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .controlSize(.large)
        }
    }
}
