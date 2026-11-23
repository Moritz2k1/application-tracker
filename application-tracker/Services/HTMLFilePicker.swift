import AppKit
import UniformTypeIdentifiers

enum HTMLFilePicker {
    @MainActor
    static func pickFiles() -> [URL] {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.html, .image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "Import"
        panel.message = "Choose the HTML file and the images it uses (⌘-click to select several)"

        return panel.runModal() == .OK ? panel.urls : []
    }

    @MainActor
    static func pickImages() -> [URL] {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "Add"
        panel.message = "Choose images to use in the document, e.g. <img src=\"photo.jpg\">"

        return panel.runModal() == .OK ? panel.urls : []
    }
}
