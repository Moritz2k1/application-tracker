//
//  DocumentView.swift
//  application-tracker
//
//  Created by Moritz Gutschi on 23.11.26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DocumentView: View {
    let application: JobApplication

    @State private var isImporting = false
    @State private var isConfirmingRemove = false
    @State private var pendingDocument: HTMLImporter.ImportedDocument?
    @State private var errorMessage: String?

    var body: some View {
        content
            .navigationTitle("\(application.company) – \(application.jobTitle)")
            .navigationSubtitle(application.htmlFileName ?? "No document")
            .toolbar { toolbarContent }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.html]) { result in
                switch result {
                case .success(let url):
                    handleImport(of: url)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
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
        if let html = application.htmlContent {
            HTMLPreviewView(html: html)
        } else {
            ContentUnavailableView {
                Label("No document yet", systemImage: "doc.badge.plus")
            } description: {
                Text("Import an HTML file, or drop one here.")
            } actions: {
                Button("Import HTML…") { isImporting = true }
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
        ToolbarItemGroup {
            Button {
                isImporting = true
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

            Button(role: .destructive) {
                isConfirmingRemove = true
            } label: {
                Label("Remove Document", systemImage: "trash")
            }
            .disabled(!application.hasDocument)
            .help("Remove the HTML from this application")
        }
    }

    private func handleImport(of url: URL) {
        do {
            let document = try HTMLImporter.importDocument(from: url)
            if application.hasDocument {
                pendingDocument = document // ask before overwriting
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

    private var isConfirmingReplace: Binding<Bool> {
        Binding(get: { pendingDocument != nil },
                set: { if !$0 { pendingDocument = nil } })
    }

    private var hasError: Binding<Bool> {
        Binding(get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } })
    }
}
