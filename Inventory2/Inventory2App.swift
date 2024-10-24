import SwiftUI

@main
@available(iOS 16.0, *)
struct Inventory2App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .preferredColorScheme(.dark) // optional: adds dark mode by default
        }
    }
}
