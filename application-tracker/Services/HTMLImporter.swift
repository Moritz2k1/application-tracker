import Foundation

enum HTMLImporter {
    struct ImportedDocument {
        let fileName: String
        let content: String
    }

    static func isHTMLFile(_ url: URL) -> Bool {
        ["html", "htm"].contains(url.pathExtension.lowercased())
    }

    static func importDocument(from url: URL) throws -> ImportedDocument {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }

        let data = try Data(contentsOf: url)

        let content = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .windowsCP1252)
            ?? String(decoding: data, as: UTF8.self)

        return ImportedDocument(fileName: url.lastPathComponent, content: content)
    }
}
