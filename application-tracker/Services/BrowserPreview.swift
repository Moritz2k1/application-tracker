import AppKit

enum BrowserPreview {
    static func open(html: String, fileName: String, assets: [DocumentAsset]) throws {
        var baseName = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        if baseName.isEmpty { baseName = "preview" }

        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrowserPreview", isDirectory: true)
            .appendingPathComponent(baseName, isDirectory: true)
        try? FileManager.default.removeItem(at: folder)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let references = relativeReferences(in: html)
        for asset in assets {
            let paths = references.filter {
                URL(fileURLWithPath: $0).lastPathComponent.caseInsensitiveCompare(asset.fileName) == .orderedSame
            }
            for path in Set([asset.fileName] + paths) {
                let assetURL = folder.appendingPathComponent(path)
                try FileManager.default.createDirectory(
                    at: assetURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try asset.data.write(to: assetURL)
            }
        }

        let fileURL = folder
            .appendingPathComponent(baseName)
            .appendingPathExtension("html")

        try html.write(to: fileURL, atomically: true, encoding: .utf8)
        NSWorkspace.shared.open(fileURL)
    }

    private static func relativeReferences(in html: String) -> Set<String> {
        let pattern = /(?:src|href)\s*=\s*["']([^"']+)["']|url\(\s*["']?([^"')]+?)["']?\s*\)/
            .ignoresCase()

        var references = Set<String>()
        for match in html.matches(of: pattern) {
            guard let raw = match.output.1 ?? match.output.2 else { continue }
            var path = String(raw).trimmingCharacters(in: .whitespaces)
            if let end = path.firstIndex(where: { $0 == "?" || $0 == "#" }) {
                path = String(path[..<end])
            }
            path = path.removingPercentEncoding ?? path

            guard !path.isEmpty,
                  !path.contains(":"),
                  !path.hasPrefix("/"),
                  !path.split(separator: "/").contains("..") else { continue }
            references.insert(path)
        }
        return references
    }
}
