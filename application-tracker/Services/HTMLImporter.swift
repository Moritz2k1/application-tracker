import Foundation
import UniformTypeIdentifiers

enum HTMLImporter {
    struct ImportedDocument {
        let fileName: String
        let content: String
    }

    struct ImportedImage {
        let fileName: String
        let data: Data
    }

    struct ImportResult {
        var document: ImportedDocument?
        var images: [ImportedImage] = []
    }

    nonisolated static func isHTMLFile(_ url: URL) -> Bool {
        ["html", "htm"].contains(url.pathExtension.lowercased())
    }

    nonisolated static func isImageFile(_ url: URL) -> Bool {
        UTType(filenameExtension: url.pathExtension)?.conforms(to: .image) ?? false
    }

    nonisolated static func isSupportedFile(_ url: URL) -> Bool {
        isHTMLFile(url) || isImageFile(url)
    }

    static func importFiles(from urls: [URL]) throws -> ImportResult {
        var result = ImportResult()
        for url in urls {
            if isHTMLFile(url), result.document == nil {
                result.document = try importDocument(from: url)
            } else if isImageFile(url) {
                result.images.append(try importImage(from: url))
            }
        }
        return result
    }

    static func importDocument(from url: URL) throws -> ImportedDocument {
        let data = try readData(from: url)

        let content = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .windowsCP1252)
            ?? String(decoding: data, as: UTF8.self)

        return ImportedDocument(fileName: url.lastPathComponent, content: content)
    }

    static func importImage(from url: URL) throws -> ImportedImage {
        ImportedImage(fileName: url.lastPathComponent, data: try readData(from: url))
    }

    private static func readData(from url: URL) throws -> Data {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }
        return try Data(contentsOf: url)
    }
}
