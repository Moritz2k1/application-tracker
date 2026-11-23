import SwiftUI

struct NameFormView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let placeholder: String
    let actionTitle: String
    let onSave: (String) -> Void

    @State private var name: String

    init(
        title: String,
        placeholder: String,
        initialName: String = "",
        actionTitle: String,
        onSave: @escaping (String) -> Void
    ) {
        self.title = title
        self.placeholder = placeholder
        self.actionTitle = actionTitle
        self.onSave = onSave
        _name = State(initialValue: initialName)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                IconTile(systemImage: "person.text.rectangle.fill", size: 30)
                Text(title)
                    .font(.headline)
            }

            TextField(placeholder, text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit(save)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(actionTitle, action: save)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(trimmedName.isEmpty)
            }
        }
        .padding()
        .frame(width: 360)
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        onSave(trimmedName)
        dismiss()
    }
}

#Preview {
    NameFormView(title: "New CV", placeholder: "Name", actionTitle: "Create") { _ in }
}
