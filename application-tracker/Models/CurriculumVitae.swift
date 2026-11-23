import Foundation
import SwiftData

@Model
final class CurriculumVitae {
    var name: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CVVersion.cv)
    var versions: [CVVersion]? = []

    init(name: String) {
        self.name = name
        self.createdAt = .now
        self.updatedAt = .now
    }
}

extension CurriculumVitae {
    var sortedVersions: [CVVersion] {
        (versions ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    var nextVersionLabel: String {
        let labels = Set((versions ?? []).map(\.label))
        var number = (versions?.count ?? 0) + 1
        while labels.contains("Version \(number)") {
            number += 1
        }
        return "Version \(number)"
    }

    @discardableResult
    func addVersion(copying source: CVVersion? = nil) -> CVVersion {
        let version = CVVersion(label: nextVersionLabel)
        modelContext?.insert(version)
        version.cv = self

        if let source {
            version.htmlContent = source.htmlContent
            version.htmlFileName = source.htmlFileName
            for asset in source.assets ?? [] {
                version.addAsset(fileName: asset.fileName, data: asset.data)
            }
        }

        updatedAt = .now
        return version
    }
}

@Model
final class CVVersion {
    var label: String
    var htmlContent: String?
    var htmlFileName: String?
    var createdAt: Date
    var updatedAt: Date

    var cv: CurriculumVitae?

    @Relationship(deleteRule: .cascade, inverse: \DocumentAsset.cvVersion)
    var assets: [DocumentAsset]? = []

    init(label: String) {
        self.label = label
        self.htmlContent = nil
        self.htmlFileName = nil
        self.createdAt = .now
        self.updatedAt = .now
    }
}

extension CVVersion: EditableDocument {
    var documentTitle: String {
        "\(cv?.name ?? "CV") – \(label)"
    }

    var blankTemplate: String {
        HTMLTemplate.cv(name: cv?.name ?? "CV")
    }

    var defaultFileName: String {
        HTMLTemplate.fileName(for: cv?.name ?? "cv")
    }

    func link(_ asset: DocumentAsset) {
        asset.cvVersion = self
    }
}
