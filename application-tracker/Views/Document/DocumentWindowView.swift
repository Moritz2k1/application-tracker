import SwiftUI
import SwiftData

struct DocumentWindowView: View {
    @Query private var matches: [JobApplication]

    init(applicationID: PersistentIdentifier) {
        _matches = Query(filter: #Predicate<JobApplication> { application in
            application.persistentModelID == applicationID
        })
    }

    var body: some View {
        if let application = matches.first {
            DocumentView(application: application)
        } else {
            ContentUnavailableView(
                "Application not found",
                systemImage: "questionmark.folder",
                description: Text("It may have been deleted.")
            )
        }
    }
}
