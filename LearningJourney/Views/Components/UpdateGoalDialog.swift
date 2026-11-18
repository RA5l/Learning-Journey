import SwiftUI

struct UpdateGoalDialog: View {
    let onDismiss: () -> Void
    let onUpdate: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(alignment: .leading, spacing: 8) {
                Text("Update goal")
                    .font(.headline)

                Text("If you update now, your streak will start over.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Button(action: onDismiss) {
                        Text("Dismiss")
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)

                    Button(action: onUpdate) {
                        Text("Update")
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.learned)
                }
                .controlSize(.large)
                .padding(.top, 12)
            }
            .padding(20)
            .frame(width: 300)
            .glassEffect(.regular, in: .rect(cornerRadius: 32))
            .accessibilityAddTraits(.isModal)
        }
    }
}
