//
//  HTMLTemplate.swift
//  application-tracker
//
//  Created by Moritz Gutschi on 23.11.26.
//

import Foundation

enum HTMLTemplate {
    static func blank(company: String, jobTitle: String) -> String {
        let company = escape(company)
        let jobTitle = escape(jobTitle)
        return """
        <!DOCTYPE html>
        <html lang="de">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>\(jobTitle) – \(company)</title>
          <style>
            body {
              font-family: -apple-system, "Helvetica Neue", Arial, sans-serif;
              max-width: 720px;
              margin: 48px auto;
              padding: 0 24px;
              line-height: 1.6;
              color: #222;
            }
          </style>
        </head>
        <body>
          <h1>\(jobTitle)</h1>
          <p>\(company)</p>
        </body>
        </html>
        """
    }

    static func fileName(for company: String) -> String {
        let slug = company
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        return (slug.isEmpty ? "document" : slug) + ".html"
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
