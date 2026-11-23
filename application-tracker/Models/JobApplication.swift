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
        updatedAt = .now
    }
    
    func updateContent(_ content: String) {
        htmlContent = content
        updatedAt = .now
    }
}
