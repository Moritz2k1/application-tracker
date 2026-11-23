import SwiftUI
import SwiftData

struct DocumentEditorView<Document: EditableDocument>: View {
    let document: Document
    let layout: EditorLayout
    let editor: EditorController

    @State private var draft: String
    @State private var previewHTML: String

    init(document: Document, layout: EditorLayout, editor: EditorController) {
        self.document = document
        self.layout = layout
        self.editor = editor
        let html = document.htmlContent ?? ""
        _draft = State(initialValue: html)
        _previewHTML = State(initialValue: html)
    }

    var body: some View {
        HSplitView {
            if layout.showsEditor {
                VStack(spacing: 0) {
                    CodeEditorView(text: $draft, controller: editor)
                    Divider()
                    EditorStatusBar(controller: editor)
                }
                .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
            }
            if layout.showsPreview {
                HTMLPreviewView(
                    html: previewHTML,
                    assets: document.assetResolver,
                    assetsVersion: document.assetsVersion
                )
                    .frame(minWidth: 280, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: draft) {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            commit()
        }
        .onChange(of: document.htmlContent) { _, newValue in
            guard let newValue, newValue != draft else { return }
            draft = newValue
            previewHTML = newValue
        }
        .onDisappear(perform: commit)
    }

    private func commit() {
        previewHTML = draft
        guard !document.isDeleted,
              document.htmlContent != nil,
              document.htmlContent != draft else { return }
        document.updateContent(draft)
    }
}
