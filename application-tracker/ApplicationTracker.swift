import SwiftUI
import SwiftData

enum WindowID {
    static let document = "document"
}

@main
struct ApplicationTrackerApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: JobApplication.self)
        } catch {
            fatalError("Could not open the database: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 820, minHeight: 480)
                .modelContainer(modelContainer)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        WindowGroup("Document", id: WindowID.document, for: PersistentIdentifier.self) { $applicationID in
            Group {
                if let applicationID {
                    DocumentWindowView(applicationID: applicationID)
                } else {
                    ContentUnavailableView("No application selected", systemImage: "doc")
                }
            }
            .frame(minWidth: 600, minHeight: 500)
            .modelContainer(modelContainer)
        }
        .defaultSize(width: 1000, height: 800)
    }
}
