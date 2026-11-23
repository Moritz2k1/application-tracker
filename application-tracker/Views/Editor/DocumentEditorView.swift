import SwiftUI
import SwiftData

struct DocumentEditorView: View {
    let application: JobApplication
    let layout: EditorLayout
    let editor: EditorController

    @State private var draft: String
    @State private var previewHTML: String

    init(application: JobApplication, layout: EditorLayout, editor: EditorController) {
        self.application = application
        self.layout = layout
        self.editor = editor
        let html = application.htmlContent ?? ""
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
                HTMLPreviewView(html: previewHTML)
                    .frame(minWidth: 280, maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: draft) {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            commit()
        }
        .onChange(of: application.htmlContent) { _, newValue in
            guard let newValue, newValue != draft else { return }
            draft = newValue
            previewHTML = newValue
        }
        .onDisappear(perform: commit)
    }

    private func commit() {
        previewHTML = draft
        guard !application.isDeleted,
              application.htmlContent != nil,
              application.htmlContent != draft else { return }
        application.updateContent(draft)
    }
}
