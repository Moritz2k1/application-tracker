//
//  DocumentView.swift
//  application-tracker
//
//  Created by Moritz Gutschi on 23.11.26.
//

import SwiftUI
import SwiftData

struct DocumentView: View {
    let application: JobApplication

    @AppStorage("editorLayout") private var layout: EditorLayout = .split
    @State private var isConfirmingRemove = false
    @State private var pendingDocument: HTMLImporter.ImportedDocument?
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
                presenting: pendingDocument
            ) { document in
                Button("Replace with \(document.fileName)", role: .destructive) {
                    application.attachDocument(content: document.content, fileName: document.fileName)
                }
            } message: { _ in
                Text("\(application.htmlFileName ?? "The current document") will be overwritten.")
            }
            .confirmationDialog("Remove the document?", isPresented: $isConfirmingRemove) {
                Button("Remove", role: .destructive) { application.removeDocument() }
            } message: {
                Text("The HTML is removed from the app. The original file on disk stays untouched.")
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
                Text("Start from a blank template, import an HTML file, or drop one here.")
            } actions: {
                Button("New Document") { createBlankDocument() }
                Button("Import HTML…") { importFile() }
            }
            .dropDestination(for: URL.self) { urls, _ in
                guard let url = urls.first, HTMLImporter.isHTMLFile(url) else { return false }
                handleImport(of: url)
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
                importFile()
            } label: {
                Label(application.hasDocument ? "Replace HTML…" : "Import HTML…",
                      systemImage: "square.and.arrow.down")
            }
            .help("Import an HTML file")

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

    private func importFile() {
        guard let url = HTMLFilePicker.pickFile() else { return }
        handleImport(of: url)
    }

    private func handleImport(of url: URL) {
        do {
            let document = try HTMLImporter.importDocument(from: url)
            if application.hasDocument {
                pendingDocument = document
            } else {
                application.attachDocument(content: document.content, fileName: document.fileName)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func openInBrowser() {
        guard let html = application.htmlContent else { return }
        do {
            try BrowserPreview.open(html: html, fileName: application.htmlFileName ?? "preview.html")
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
                let exporter = PDFExporter()
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
        Binding(get: { pendingDocument != nil },
                set: { if !$0 { pendingDocument = nil } })
    }

    private var hasError: Binding<Bool> {
        Binding(get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } })
    }
}
