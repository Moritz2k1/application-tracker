import Foundation
import SwiftData

protocol EditableDocument: PersistentModel {
    var htmlContent: String? { get set }
    var htmlFileName: String? { get set }
    var assets: [DocumentAsset]? { get }
    var updatedAt: Date { get set }

    var documentTitle: String { get }
    var blankTemplate: String { get }
    var defaultFileName: String { get }

    func link(_ asset: DocumentAsset)
}

extension EditableDocument {
    var hasDocument: Bool {
        htmlContent != nil
    }

    func createBlankDocument() {
        attachDocument(content: blankTemplate, fileName: defaultFileName)
    }

    func attachDocument(content: String, fileName: String) {
        htmlContent = content
        htmlFileName = fileName
        updatedAt = .now
    }

    func removeDocument() {
        htmlContent = nil
        htmlFileName = nil
        for asset in assets ?? [] {
            modelContext?.delete(asset)
        }
        updatedAt = .now
    }

    func updateContent(_ content: String) {
        htmlContent = content
        updatedAt = .now
    }
}

extension EditableDocument {
    var sortedAssets: [DocumentAsset] {
        (assets ?? []).sorted { $0.fileName.localizedStandardCompare($1.fileName) == .orderedAscending }
    }

    var assetsVersion: String {
        (assets ?? [])
            .map { "\($0.fileName)@\($0.addedAt.timeIntervalSinceReferenceDate)" }
            .sorted()
            .joined(separator: "|")
    }

    var assetResolver: AssetResolver {
        { [weak self] name in
            guard let asset = self?.asset(named: name) else { return nil }
            return AssetFile(data: asset.data, mimeType: asset.mimeType)
        }
    }

    func asset(named name: String) -> DocumentAsset? {
        (assets ?? []).first { $0.fileName.caseInsensitiveCompare(name) == .orderedSame }
    }

    func addAsset(fileName: String, data: Data) {
        if let existing = asset(named: fileName) {
            existing.data = data
            existing.addedAt = .now
        } else {
            let asset = DocumentAsset(fileName: fileName, data: data)
            modelContext?.insert(asset)
            link(asset)
        }
        updatedAt = .now
    }

    func removeAsset(_ asset: DocumentAsset) {
        modelContext?.delete(asset)
        updatedAt = .now
    }
}
