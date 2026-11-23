//
//  ApplicationStatus.swift
//  application-tracker
//
//  Created by Moritz Gutschi on 23.11.26.
//

import Foundation

enum ApplicationStatus: String, CaseIterable, Identifiable, Codable {
    case draft
    case applied
    case interview
    case offer
    case rejected
    case withdrawn

    var id: Self { self }

    var label: String {
        switch self {
        case .draft: "Draft"
        case .applied: "Applied"
        case .interview: "Interview"
        case .offer: "Offer"
        case .rejected: "Rejected"
        case .withdrawn: "Withdrawn"
        }
    }

    var systemImage: String {
        switch self {
        case .draft: "pencil"
        case .applied: "paperplane"
        case .interview: "person.2"
        case .offer: "checkmark.seal"
        case .rejected: "xmark.circle"
        case .withdrawn: "arrow.uturn.backward"
        }
    }
}

extension ApplicationStatus: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        let order = Self.allCases
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}
