import SwiftUI

@main
struct MyApp: App {
    @State private var store = ProgressStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .ignoresSafeArea(.keyboard)
                .tint(.primary)
                .environment(\.locale, Locale(identifier: "en_US"))
                .environment(\.calendar, .journey)
        }
    }
}
