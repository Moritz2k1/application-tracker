import SwiftUI
import WebKit

struct HTMLPreviewView: NSViewRepresentable {
    let html: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.load(html, in: webView)
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        private var lastLoadedHTML: String?
        private var scrollYToRestore: Double = 0

        func load(_ html: String, in webView: WKWebView) {
            guard html != lastLoadedHTML else { return }
            let isFirstLoad = lastLoadedHTML == nil
            lastLoadedHTML = html

            guard !isFirstLoad else {
                webView.loadHTMLString(html, baseURL: nil)
                return
            }

            webView.evaluateJavaScript("window.scrollY") { [weak self] result, _ in
                self?.scrollYToRestore = (result as? Double) ?? 0
                webView.loadHTMLString(html, baseURL: nil)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard scrollYToRestore > 0 else { return }
            webView.evaluateJavaScript("window.scrollTo(0, \(scrollYToRestore))")
            scrollYToRestore = 0
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            guard let url = navigationAction.request.url else { return .cancel }

            if navigationAction.targetFrame?.isMainFrame == false {
                return .allow
            }
            if url.scheme == "about" {
                return .allow
            }
            if navigationAction.navigationType == .linkActivated {
                NSWorkspace.shared.open(url)
            }
            return .cancel
        }
    }
}
