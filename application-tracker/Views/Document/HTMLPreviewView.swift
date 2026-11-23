import SwiftUI
import WebKit

struct HTMLPreviewView: NSViewRepresentable {
    let html: String
    let assets: AssetResolver
    let assetsVersion: String

    func makeCoordinator() -> Coordinator {
        Coordinator(assets: assets)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(context.coordinator.schemeHandler, forURLScheme: AssetSchemeHandler.scheme)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.schemeHandler.resolve = assets
        context.coordinator.load(html, assetsVersion: assetsVersion, in: webView)
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        let schemeHandler: AssetSchemeHandler
        private var lastLoadedHTML: String?
        private var lastAssetsVersion: String?
        private var scrollYToRestore: Double = 0

        init(assets: @escaping AssetResolver) {
            schemeHandler = AssetSchemeHandler(resolve: assets)
        }

        func load(_ html: String, assetsVersion: String, in webView: WKWebView) {
            guard html != lastLoadedHTML || assetsVersion != lastAssetsVersion else { return }
            let isFirstLoad = lastLoadedHTML == nil
            lastLoadedHTML = html
            lastAssetsVersion = assetsVersion

            guard !isFirstLoad else {
                webView.loadHTMLString(html, baseURL: AssetSchemeHandler.baseURL)
                return
            }

            webView.evaluateJavaScript("window.scrollY") { [weak self] result, _ in
                self?.scrollYToRestore = (result as? Double) ?? 0
                webView.loadHTMLString(html, baseURL: AssetSchemeHandler.baseURL)
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
            if url.scheme == AssetSchemeHandler.scheme {
                let isLinkToOtherPage = navigationAction.navigationType == .linkActivated && url.fragment == nil
                return isLinkToOtherPage ? .cancel : .allow
            }
            if navigationAction.navigationType == .linkActivated {
                NSWorkspace.shared.open(url)
            }
            return .cancel
        }
    }
}
