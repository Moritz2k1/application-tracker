import AppKit
import UniformTypeIdentifiers

enum PDFSavePanel {
    @MainActor
    static func chooseDestination(suggestedName: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = suggestedName
        panel.prompt = "Export"
        panel.message = "Export the document as PDF"

        return panel.runModal() == .OK ? panel.url : nil
    }
}
