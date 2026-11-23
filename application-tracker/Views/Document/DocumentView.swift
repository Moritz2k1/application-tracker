import SwiftUI
import SwiftData

struct DocumentView: View {
    let application: JobApplication

    @AppStorage("editorLayout") private var layout: EditorLayout = .split
    @State private var isConfirmingRemove = false
    @State private var pendingImport: HTMLImporter.ImportResult?
    @State private var errorMessage: String?
    @State private var editor = EditorController()
    @State private var isExportingPDF = false

    var body: some View {
        content
            .navigationTitle("\(application.company) – \(application.jobTitle)")
            .navigationSubtitle(application.htmlFileName ?? "No document")
            .toolbar { toolbarContent }
            .confirmationDialog(
                "Replace the current document?",
                isPresented: isConfirmingReplace,
                presenting: pendingImport?.document
            ) { document in
                Button("Replace with \(document.fileName)", role: .destructive) {
                    if let pendingImport { apply(pendingImport) }
                }
            } message: { _ in
                Text("\(application.htmlFileName ?? "The current document") will be overwritten.")
            }
            .confirmationDialog("Remove the document?", isPresented: $isConfirmingRemove) {
                Button("Remove", role: .destructive) { application.removeDocument() }
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
        if application.hasDocument {
            DocumentEditorView(application: application, layout: layout, editor: editor)
        } else {
            ContentUnavailableView {
                Label("No document yet", systemImage: "doc.badge.plus")
            } description: {
                Text("Start from a blank template, import an HTML file with its images, or drop them here.")
            } actions: {
                Button("New Document") { createBlankDocument() }
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
            .disabled(!application.hasDocument)
            .help("Editor, editor and preview, or preview only")
        }

        ToolbarItemGroup {
            Button {
                editor.format()
            } label: {
                Label("Format", systemImage: "text.alignleft")
            }
            .disabled(!application.hasDocument || !layout.showsEditor || !editor.isReady)
            .help("Format with Prettier (⇧⌥F in the editor)")
            
            Button {
                importFiles()
            } label: {
                Label(application.hasDocument ? "Replace HTML…" : "Import HTML…",
                      systemImage: "square.and.arrow.down")
            }
            .help("Import an HTML file together with its images")

            Menu {
                Button("Add Images…") { addImages() }
                let assets = application.sortedAssets
                if !assets.isEmpty {
                    Section("Images") {
                        ForEach(assets) { asset in
                            Menu(asset.fileName) {
                                Button("Copy <img> Tag") { copyImageTag(for: asset) }
                                Button("Remove", role: .destructive) { application.removeAsset(asset) }
                            }
                        }
                    }
                }
            } label: {
                Label("Images", systemImage: "photo.on.rectangle")
            }
            .disabled(!application.hasDocument)
            .help("Images used by the document, referenced by file name, e.g. <img src=\"photo.jpg\">")

            Button {
                openInBrowser()
            } label: {
                Label("Open in Browser", systemImage: "safari")
            }
            .disabled(!application.hasDocument)
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
            .disabled(!application.hasDocument || isExportingPDF)
            .keyboardShortcut("e", modifiers: [.command, .shift])
            .help("Export as A4 PDF (⇧⌘E)")

            Button(role: .destructive) {
                isConfirmingRemove = true
            } label: {
                Label("Remove Document", systemImage: "trash")
            }
            .disabled(!application.hasDocument)
            .help("Remove the HTML from this application")
        }
    }

    private func createBlankDocument() {
        application.attachDocument(
            content: HTMLTemplate.blank(company: application.company, jobTitle: application.jobTitle),
            fileName: HTMLTemplate.fileName(for: application.company)
        )
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
            if result.document == nil, !application.hasDocument {
                errorMessage = "Choose an HTML file to create the document. You can select its images together with it."
            } else if result.document != nil, application.hasDocument {
                pendingImport = result
            } else {
                apply(result)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func apply(_ result: HTMLImporter.ImportResult) {
        if let document = result.document {
            application.attachDocument(content: document.content, fileName: document.fileName)
        }
        for image in result.images {
            application.addAsset(fileName: image.fileName, data: image.data)
        }
    }

    private func copyImageTag(for asset: DocumentAsset) {
        let name = URL(fileURLWithPath: asset.fileName).deletingPathExtension().lastPathComponent
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("<img src=\"\(asset.fileName)\" alt=\"\(name)\">", forType: .string)
    }

    private func openInBrowser() {
        guard let html = application.htmlContent else { return }
        do {
            try BrowserPreview.open(
                html: html,
                fileName: application.htmlFileName ?? "preview.html",
                assets: application.assets ?? []
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func exportPDF() {
        guard let html = application.htmlContent,
              let url = PDFSavePanel.chooseDestination(suggestedName: pdfFileName) else { return }

        isExportingPDF = true
        Task {
            defer { isExportingPDF = false }
            do {
                let exporter = PDFExporter(assets: application.assetResolver)
                try await exporter.export(html: html, to: url)
                NSWorkspace.shared.open(url)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private var pdfFileName: String {
        let source = application.htmlFileName ?? HTMLTemplate.fileName(for: application.company)
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
