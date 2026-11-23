import Foundation
import SwiftData

@Model
final class JobApplication {
    var company: String
    var jobTitle: String
    var appliedOn: Date

    var statusRaw: String

    var notes: String

    var htmlContent: String?
    var htmlFileName: String?

    @Relationship(deleteRule: .cascade, inverse: \DocumentAsset.application)
    var assets: [DocumentAsset]? = []

    var createdAt: Date
    var updatedAt: Date

    init(
        company: String,
        jobTitle: String,
        appliedOn: Date = .now,
        status: ApplicationStatus = .applied,
        notes: String = ""
    ) {
        self.company = company
        self.jobTitle = jobTitle
        self.appliedOn = appliedOn
        self.statusRaw = status.rawValue
        self.notes = notes
        self.htmlContent = nil
        self.htmlFileName = nil
        self.createdAt = .now
        self.updatedAt = .now
    }
}

extension JobApplication {
    var status: ApplicationStatus {
        get { ApplicationStatus(rawValue: statusRaw) ?? .applied }
        set { statusRaw = newValue.rawValue }
    }

    var year: Int {
        Calendar.current.component(.year, from: appliedOn)
    }

    var hasDocument: Bool {
        htmlContent != nil
    }
}

extension JobApplication {
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

extension JobApplication {
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
            asset.application = self
        }
        updatedAt = .now
    }

    func removeAsset(_ asset: DocumentAsset) {
        modelContext?.delete(asset)
        updatedAt = .now
    }
}
