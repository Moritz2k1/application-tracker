import Foundation
import WebKit

struct AssetFile {
    let data: Data
    let mimeType: String
}

typealias AssetResolver = (String) -> AssetFile?

final class AssetSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "asset"
    static let baseURL = URL(string: "\(scheme)://document/")!

    var resolve: AssetResolver

    init(resolve: @escaping AssetResolver) {
        self.resolve = resolve
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url,
              let file = resolve(url.lastPathComponent) else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        let response = URLResponse(
            url: url,
            mimeType: file.mimeType,
            expectedContentLength: file.data.count,
            textEncodingName: nil
        )
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(file.data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) { }
}
