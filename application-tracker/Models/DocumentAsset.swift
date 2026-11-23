import Foundation
import SwiftData
import UniformTypeIdentifiers

@Model
final class DocumentAsset {
    var fileName: String
    @Attribute(.externalStorage) var data: Data
    var addedAt: Date

    var application: JobApplication?
    var cvVersion: CVVersion?

    init(fileName: String, data: Data) {
        self.fileName = fileName
        self.data = data
        self.addedAt = .now
    }
}

extension DocumentAsset {
    var mimeType: String {
        let pathExtension = URL(fileURLWithPath: fileName).pathExtension
        return UTType(filenameExtension: pathExtension)?.preferredMIMEType ?? "application/octet-stream"
    }
}
