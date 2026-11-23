import SwiftUI
import WebKit

struct CodeEditorView: NSViewRepresentable {
    @Binding var text: String
    let controller: EditorController

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, controller: controller)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: Coordinator.handlerName)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        context.coordinator.attach(to: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.text = $text
        context.coordinator.syncText(text)
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Coordinator.handlerName)
        coordinator.detach(from: webView)
    }

    @MainActor
    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        static let handlerName = "editor"

        var text: Binding<String>
        private let controller: EditorController
        private weak var webView: WKWebView?
        private var editorURL: URL?
        private var isReady = false
        private var textInEditor: String?

        init(text: Binding<String>, controller: EditorController) {
            self.text = text
            self.controller = controller
        }

        func attach(to webView: WKWebView) {
            self.webView = webView
            controller.webView = webView
            controller.isReady = false

            guard let url = Bundle.main.url(forResource: "editor", withExtension: "html") else {
                controller.loadError = "editor.html is missing. Run npm run build in EditorWeb."
                return
            }
            controller.loadError = nil
            editorURL = url
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        func detach(from webView: WKWebView) {
            isReady = false
            guard controller.webView === webView else { return }
            controller.webView = nil
            controller.isReady = false
        }

        func syncText(_ newText: String) {
            guard isReady, newText != textInEditor else { return }
            textInEditor = newText
            webView?.callAsyncJavaScript(
                "window.editorBridge.setContent(text)",
                arguments: ["text": newText],
                in: nil,
                in: .page,
                completionHandler: nil
            )
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard let body = message.body as? [String: Any],
                  let type = body["type"] as? String else { return }

            switch type {
            case "ready":
                isReady = true
                controller.isReady = true
                textInEditor = nil
                syncText(text.wrappedValue)
            case "change":
                guard let newText = body["text"] as? String else { return }
                textInEditor = newText
                controller.formatError = nil
                if text.wrappedValue != newText {
                    text.wrappedValue = newText
                }
            case "lint":
                controller.errorCount = body["errors"] as? Int ?? 0
                controller.warningCount = body["warnings"] as? Int ?? 0
            case "formatted":
                controller.formatError = nil
            case "formatError":
                controller.formatError = body["message"] as? String
            default:
                break
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            guard let requested = navigationAction.request.url?.standardizedFileURL,
                  let editorURL = editorURL?.standardizedFileURL,
                  requested == editorURL else { return .cancel }
            return .allow
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            isReady = false
            controller.isReady = false
            textInEditor = nil
            webView.reload()
        }
    }
}
