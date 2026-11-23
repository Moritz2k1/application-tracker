//
//  HTMLFilePicker.swift
//  application-tracker
//
//  Created by Moritz Gutschi on 23.11.26.
//

import AppKit
import UniformTypeIdentifiers

enum HTMLFilePicker {
    @MainActor
    static func pickFile() -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.html]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "Import"
        panel.message = "Choose the HTML file for this application"

        return panel.runModal() == .OK ? panel.url : nil
    }
}
