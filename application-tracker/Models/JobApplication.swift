//
//  JobApplication.swift
//  application-tracker
//
//  Created by Moritz Gutschi on 23.11.26.
//

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
