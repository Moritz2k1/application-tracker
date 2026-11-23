import SwiftUI
import SwiftData

struct DocumentWindowView<Document: EditableDocument>: View {
    let notFoundTitle: LocalizedStringKey

    @Query private var matches: [Document]

    init(documentID: PersistentIdentifier, notFoundTitle: LocalizedStringKey) {
        self.notFoundTitle = notFoundTitle
        _matches = Query(filter: #Predicate<Document> { document in
            document.persistentModelID == documentID
        })
    }

    var body: some View {
        if let document = matches.first {
            DocumentView(document: document)
        } else {
            ContentUnavailableView(
                notFoundTitle,
                systemImage: "questionmark.folder",
                description: Text("It may have been deleted.")
            )
        }
    }
}
