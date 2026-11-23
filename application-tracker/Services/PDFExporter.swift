import AppKit
import WebKit

@MainActor
final class PDFExporter: NSObject, WKNavigationDelegate {
    enum ExportError: LocalizedError {
        case loadFailed(String)
        case printFailed

        var errorDescription: String? {
            switch self {
            case .loadFailed(let reason): "The page could not be loaded: \(reason)"
            case .printFailed: "The PDF could not be created."
            }
        }
    }

    static let a4 = NSSize(width: 595.28, height: 841.89)

    private let webView: WKWebView
    private let window: NSWindow
    private let schemeHandler: AssetSchemeHandler
    private var loadContinuation: CheckedContinuation<Void, Error>?
    private var printContinuation: CheckedContinuation<Bool, Never>?

    init(assets: @escaping AssetResolver) {
        schemeHandler = AssetSchemeHandler(resolve: assets)

        let configuration = WKWebViewConfiguration()
        configuration.preferences.shouldPrintBackgrounds = true
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: AssetSchemeHandler.scheme)

        let frame = NSRect(origin: .zero, size: Self.a4)
        webView = WKWebView(frame: frame, configuration: configuration)
        window = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)

        super.init()

        window.contentView = webView
        webView.navigationDelegate = self
    }

    func export(html: String, to url: URL, margin: CGFloat = 42) async throws {
        try await load(html)
        try await waitForResources()
        let success = await printPDF(to: url, margin: margin)
        guard success else { throw ExportError.printFailed }
    }

    private func load(_ html: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            loadContinuation = continuation
            webView.loadHTMLString(html, baseURL: AssetSchemeHandler.baseURL)
        }
    }

    private func waitForResources() async throws {
        _ = try await webView.callAsyncJavaScript(
            """
            const images = Array.from(document.images).map((image) =>
              image.complete ? null : new Promise((resolve) => { image.onload = image.onerror = resolve; })
            );
            await Promise.race([
              Promise.all([document.fonts.ready, ...images]),
              new Promise((resolve) => setTimeout(resolve, 5000))
            ]);
            """,
            contentWorld: .page
        )
    }

    private func printPDF(to url: URL, margin: CGFloat) async -> Bool {
        let printInfo = NSPrintInfo()
        printInfo.paperSize = Self.a4
        printInfo.orientation = .portrait
        printInfo.topMargin = margin
        printInfo.bottomMargin = margin
        printInfo.leftMargin = margin
        printInfo.rightMargin = margin
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic
        printInfo.isHorizontallyCentered = true
        printInfo.isVerticallyCentered = false
        printInfo.jobDisposition = .save
        printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = url
        printInfo.dictionary()[NSPrintInfo.AttributeKey.headerAndFooter] = false

        let operation = webView.printOperation(with: printInfo)
        operation.showsPrintPanel = false
        operation.showsProgressPanel = false
        operation.view?.frame = webView.bounds

        return await withCheckedContinuation { continuation in
            printContinuation = continuation
            operation.runModal(
                for: NSApp.keyWindow ?? window,
                delegate: self,
                didRun: #selector(printOperationDidRun(_:success:contextInfo:)),
                contextInfo: nil
            )
        }
    }

    @objc private func printOperationDidRun(
        _ operation: NSPrintOperation,
        success: Bool,
        contextInfo: UnsafeMutableRawPointer?
    ) {
        printContinuation?.resume(returning: success)
        printContinuation = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadContinuation?.resume()
        loadContinuation = nil
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadContinuation?.resume(throwing: ExportError.loadFailed(error.localizedDescription))
        loadContinuation = nil
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        loadContinuation?.resume(throwing: ExportError.loadFailed(error.localizedDescription))
        loadContinuation = nil
    }
}
