import SwiftUI

struct EditorStatusBar: View {
    let controller: EditorController

    var body: some View {
        HStack(spacing: 12) {
            Label("\(controller.errorCount)", systemImage: "xmark.octagon.fill")
                .foregroundStyle(controller.errorCount > 0 ? Color.red : Color.secondary)
                .help("Errors")

            Label("\(controller.warningCount)", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(controller.warningCount > 0 ? Color.orange : Color.secondary)
                .help("Warnings")

            Spacer(minLength: 12)

            if let message = controller.loadError ?? controller.formatError {
                Text(message)
                    .foregroundStyle(.red)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .help(message)
            }
        }
        .font(.caption)
        .monospacedDigit()
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.bar)
    }
}
