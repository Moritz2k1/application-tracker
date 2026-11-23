import Foundation
import Observation
import WebKit

@MainActor
@Observable
final class EditorController {
    var isReady = false
    var errorCount = 0
    var warningCount = 0
    var formatError: String?
    var loadError: String?

    @ObservationIgnored weak var webView: WKWebView?

    func format() {
        webView?.evaluateJavaScript("void window.editorBridge.format()")
    }
}
