//
//  EditorLayout.swift
//  application-tracker
//
//  Created by Moritz Gutschi on 23.11.26.
//

import Foundation

enum EditorLayout: String, CaseIterable, Identifiable {
    case editor
    case split
    case preview

    var id: Self { self }

    var label: String {
        switch self {
        case .editor: "Editor"
        case .split: "Editor and Preview"
        case .preview: "Preview"
        }
    }

    var systemImage: String {
        switch self {
        case .editor: "chevron.left.forwardslash.chevron.right"
        case .split: "rectangle.split.2x1"
        case .preview: "eye"
        }
    }

    var showsEditor: Bool { self != .preview }
    var showsPreview: Bool { self != .editor }
}
