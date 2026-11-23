import SwiftUI
import SwiftData

@main
struct ApplicationTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 820, minHeight: 480)
        }
        // .modelContainer(for: JobApplication.self, isUndoEnabled: true)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
