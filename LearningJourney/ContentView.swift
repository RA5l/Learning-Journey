import SwiftUI

struct ContentView: View {
    let store: ProgressStore

    var body: some View {
        Group {
            if store.goal == nil {
                OnboardingView(store: store)
            } else {
                NavigationStack {
                    ActivityView(store: store)
                }
                .ignoresSafeArea(.keyboard)
            }
        }
        .animation(.default, value: store.goal == nil)
    }
}
