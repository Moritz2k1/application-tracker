import SwiftUI
import AppKit

struct CodeTextView: NSViewRepresentable {
    @Binding var text: String

    private static var font: NSFont {
        .monospacedSystemFont(ofSize: 13, weight: .regular)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }

        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.font = Self.font
        textView.textContainerInset = NSSize(width: 8, height: 10)
        textView.string = text

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.text = $text
        guard let textView = scrollView.documentView as? NSTextView,
              textView.string != text else { return }
        replaceText(in: textView, with: text, coordinator: context.coordinator)
    }

    private func replaceText(in textView: NSTextView, with newText: String, coordinator: Coordinator) {
        let fullRange = NSRange(location: 0, length: textView.string.utf16.count)
        guard textView.shouldChangeText(in: fullRange, replacementString: newText) else { return }

        coordinator.isProgrammaticChange = true
        textView.textStorage?.replaceCharacters(in: fullRange, with: newText)
        textView.font = Self.font
        textView.didChangeText()
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        coordinator.isProgrammaticChange = false
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        var isProgrammaticChange = false

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard !isProgrammaticChange,
                  let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}
