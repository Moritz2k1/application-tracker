import SwiftUI
import SwiftData

struct DocumentView<Document: EditableDocument>: View {
    let document: Document

    @AppStorage("editorLayout") private var layout: EditorLayout = .split
    @State private var isConfirmingRemove = false
    @State private var pendingImport: HTMLImporter.ImportResult?
    @State private var errorMessage: String?
    @State private var editor = EditorController()
    @State private var isExportingPDF = false

    var body: some View {
        content
            .navigationTitle(document.documentTitle)
            .navigationSubtitle(document.htmlFileName ?? "No document")
            .toolbar { toolbarContent }
            .confirmationDialog(
                "Replace the current document?",
                isPresented: isConfirmingReplace,
                presenting: pendingImport?.document
            ) { imported in
                Button("Replace with \(imported.fileName)", role: .destructive) {
                    if let pendingImport { apply(pendingImport) }
                }
            } message: { _ in
                Text("\(document.htmlFileName ?? "The current document") will be overwritten.")
            }
            .confirmationDialog("Remove the document?", isPresented: $isConfirmingRemove) {
                Button("Remove", role: .destructive) { document.removeDocument() }
            } message: {
                Text("The HTML and its images are removed from the app. The original files on disk stay untouched.")
            }
            .alert("Something went wrong", isPresented: hasError, presenting: errorMessage) { _ in
                Button("OK") { }
            } message: { message in
                Text(message)
            }
    }

    @ViewBuilder
    private var content: some View {
        if document.hasDocument {
            DocumentEditorView(document: document, layout: layout, editor: editor)
        } else {
            ContentUnavailableView {
                Label("No document yet", systemImage: "doc.badge.plus")
            } description: {
                Text("Start from a blank template, import an HTML file with its images, or drop them here.")
            } actions: {
                Button("New Document") { document.createBlankDocument() }
                Button("Import HTML…") { importFiles() }
            }
            .dropDestination(for: URL.self) { urls, _ in
                let supported = urls.filter(HTMLImporter.isSupportedFile)
                guard !supported.isEmpty else { return false }
                handleImport(of: supported)
                return true
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem {
            Picker("Layout", selection: $layout) {
                ForEach(EditorLayout.allCases) { option in
                    Label(option.label, systemImage: option.systemImage)
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)
            .labelStyle(.iconOnly)
            .disabled(!document.hasDocument)
            .help("Editor, editor and preview, or preview only")
        }

        ToolbarItemGroup {
            Button {
                editor.format()
            } label: {
                Label("Format", systemImage: "text.alignleft")
            }
            .disabled(!document.hasDocument || !layout.showsEditor || !editor.isReady)
            .help("Format with Prettier (⇧⌥F in the editor)")
            
            Button {
                importFiles()
            } label: {
                Label(document.hasDocument ? "Replace HTML…" : "Import HTML…",
                      systemImage: "square.and.arrow.down")
            }
            .help("Import an HTML file together with its images")

            Menu {
                Button("Add Images…") { addImages() }
                let assets = document.sortedAssets
                if !assets.isEmpty {
                    Section("Images") {
                        ForEach(assets) { asset in
                            Menu(asset.fileName) {
                                Button("Copy <img> Tag") { copyImageTag(for: asset) }
                                Button("Remove", role: .destructive) { document.removeAsset(asset) }
                            }
                        }
                    }
                }
            } label: {
                Label("Images", systemImage: "photo.on.rectangle")
            }
            .disabled(!document.hasDocument)
            .help("Images used by the document, referenced by file name, e.g. <img src=\"photo.jpg\">")

            Button {
                openInBrowser()
            } label: {
                Label("Open in Browser", systemImage: "safari")
            }
            .disabled(!document.hasDocument)
            .help("Show the page in your default browser")
            
            Button {
                exportPDF()
            } label: {
                if isExportingPDF {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("Export PDF", systemImage: "arrow.down.doc")
                }
            }
            .disabled(!document.hasDocument || isExportingPDF)
            .keyboardShortcut("e", modifiers: [.command, .shift])
            .help("Export as A4 PDF (⇧⌘E)")

            Button(role: .destructive) {
                isConfirmingRemove = true
            } label: {
                Label("Remove Document", systemImage: "trash")
            }
            .disabled(!document.hasDocument)
            .help("Remove the HTML and its images")
        }
    }

    private func importFiles() {
        let urls = HTMLFilePicker.pickFiles()
        guard !urls.isEmpty else { return }
        handleImport(of: urls)
    }

    private func addImages() {
        let urls = HTMLFilePicker.pickImages()
        guard !urls.isEmpty else { return }
        handleImport(of: urls)
    }

    private func handleImport(of urls: [URL]) {
        do {
            let result = try HTMLImporter.importFiles(from: urls)
            if result.document == nil, !document.hasDocument {
                errorMessage = "Choose an HTML file to create the document. You can select its images together with it."
            } else if result.document != nil, document.hasDocument {
                pendingImport = result
            } else {
                apply(result)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ result: HTMLImporter.ImportResult) {
        if let imported = result.document {
            document.attachDocument(content: imported.content, fileName: imported.fileName)
        }
        for image in result.images {
            document.addAsset(fileName: image.fileName, data: image.data)
        }
    }

    private func copyImageTag(for asset: DocumentAsset) {
        let name = URL(fileURLWithPath: asset.fileName).deletingPathExtension().lastPathComponent
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("<img src=\"\(asset.fileName)\" alt=\"\(name)\">", forType: .string)
    }

    private func openInBrowser() {
        guard let html = document.htmlContent else { return }
        do {
            try BrowserPreview.open(
                html: html,
                fileName: document.htmlFileName ?? "preview.html",
                assets: document.assets ?? []
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func exportPDF() {
        guard let html = document.htmlContent,
              let url = PDFSavePanel.chooseDestination(suggestedName: pdfFileName) else { return }

        isExportingPDF = true
        Task {
            defer { isExportingPDF = false }
            do {
                let exporter = PDFExporter(assets: document.assetResolver)
                try await exporter.export(html: html, to: url)
                NSWorkspace.shared.open(url)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private var pdfFileName: String {
        let source = document.htmlFileName ?? document.defaultFileName
        return URL(fileURLWithPath: source).deletingPathExtension().lastPathComponent + ".pdf"
    }

    private var isConfirmingReplace: Binding<Bool> {
        Binding(get: { pendingImport?.document != nil },
                set: { if !$0 { pendingImport = nil } })
    }

    private var hasError: Binding<Bool> {
        Binding(get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } })
    }
}
