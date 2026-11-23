import AppKit

enum BrowserPreview {
    static func open(html: String, fileName: String) throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrowserPreview", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        var baseName = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        if baseName.isEmpty { baseName = "preview" }

        let fileURL = folder
            .appendingPathComponent(baseName)
            .appendingPathExtension("html")

        try html.write(to: fileURL, atomically: true, encoding: .utf8)
        NSWorkspace.shared.open(fileURL)
    }
}
