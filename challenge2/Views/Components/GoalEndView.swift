import SwiftUI

struct GoalEndView: View {
    let didSucceed: Bool
    let onSetGoal: () -> Void

    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: didSucceed ? "hands.clap.fill" : "xmark.seal")
                .font(.system(size: 44))
                .foregroundStyle(.learned)
                .symbolEffect(.bounce, value: hasAppeared)
                .scaleEffect(hasAppeared ? 1 : 0.3)
                .padding(.bottom, 10)
                .accessibilityHidden(true)

            Group {
                Text(didSucceed ? "Well done!" : "You didn't reach your goal this time.")
                    .font(.headline)

                Text(didSucceed ? "Ready for your next goal?" : "Want to set another goal?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button(action: onSetGoal) {
                    Label("Set a goal", systemImage: "pencil.and.outline")
                        .foregroundStyle(.white)
                }
                .buttonStyle(.glassProminent)
                .tint(.learned)
                .controlSize(.large)
                .padding(.top, 40)
            }
            .offset(y: hasAppeared ? 0 : 12)
        }
        .opacity(hasAppeared ? 1 : 0)
        .multilineTextAlignment(.center)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.4)) {
                hasAppeared = true
            }
        }
    }
}
