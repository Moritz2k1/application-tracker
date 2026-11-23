import SwiftUI
import SwiftData

struct CVLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow

    @Query(sort: \CurriculumVitae.name) private var cvs: [CurriculumVitae]

    @State private var selection: CVVersion.ID?
    @State private var nameSheet: NameSheet?

    var body: some View {
        List(selection: $selection) {
            ForEach(cvs) { cv in
                Section {
                    let versions = cv.sortedVersions
                    if versions.isEmpty {
                        Text("No versions")
                            .foregroundStyle(.secondary)
                            .selectionDisabled()
                    }
                    ForEach(versions) { version in
                        CVVersionRow(version: version)
                            .tag(version.id)
                    }
                } header: {
                    CVHeader(cv: cv)
                        .contextMenu { cvActions(for: cv) }
                }
            }
        }
        .contextMenu(forSelectionType: CVVersion.ID.self) { ids in
            if let version = version(in: ids) {
                Button("Open") { open(version) }
                Button("New Version From This") { addVersion(to: version.cv, copying: version) }
                Button("Rename Version…") { nameSheet = .renameVersion(version) }
                Divider()
                Button("Delete Version", role: .destructive) { delete(version) }
                if let cv = version.cv {
                    Divider()
                    cvActions(for: cv)
                }
            }
        } primaryAction: { ids in
            if let version = version(in: ids) {
                open(version)
            }
        }
        .onDeleteCommand {
            if let selectedVersion { delete(selectedVersion) }
        }
        .overlay {
            if cvs.isEmpty {
                ContentUnavailableView {
                    Label("No CVs yet", systemImage: "person.text.rectangle")
                } description: {
                    Text("Create a CV and keep different versions of it, e.g. one per kind of job.")
                } actions: {
                    Button("New CV") { nameSheet = .newCV }
                }
            }
        }
        .toolbar { toolbarContent }
        .navigationTitle("CVs")
        .navigationSubtitle(cvs.count == 1 ? "1 CV" : "\(cvs.count) CVs")
        .sheet(item: $nameSheet, content: sheet)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            Button {
                nameSheet = .newCV
            } label: {
                Label("New CV", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
            .help("New CV (⌘N)")

            Button {
                if let selectedVersion {
                    addVersion(to: selectedVersion.cv, copying: selectedVersion)
                }
            } label: {
                Label("New Version", systemImage: "plus.square.on.square")
            }
            .disabled(selectedVersion == nil)
            .help("Duplicate the selected version to start a new one")

            Button {
                if let selectedVersion { open(selectedVersion) }
            } label: {
                Label("Open Document", systemImage: "doc.richtext")
            }
            .disabled(selectedVersion == nil)
            .help("Open the version in the editor (double-click a row)")

            Button(role: .destructive) {
                if let selectedVersion { delete(selectedVersion) }
            } label: {
                Label("Delete Version", systemImage: "trash")
            }
            .disabled(selectedVersion == nil)
            .help("Delete the selected version (⌘Z to undo)")
        }
    }

    @ViewBuilder
    private func cvActions(for cv: CurriculumVitae) -> some View {
        Button("New Empty Version") { addVersion(to: cv, copying: nil) }
        Button("Rename CV…") { nameSheet = .renameCV(cv) }
        Button("Delete CV", role: .destructive) { delete(cv) }
    }

    @ViewBuilder
    private func sheet(for sheet: NameSheet) -> some View {
        switch sheet {
        case .newCV:
            NameFormView(title: "New CV", placeholder: "e.g. Software Developer CV", actionTitle: "Create") { name in
                createCV(named: name)
            }
        case .renameCV(let cv):
            NameFormView(title: "Rename CV", placeholder: "Name", initialName: cv.name, actionTitle: "Rename") { name in
                cv.name = name
                cv.updatedAt = .now
            }
        case .renameVersion(let version):
            NameFormView(
                title: "Rename Version",
                placeholder: "e.g. Backend focus",
                initialName: version.label,
                actionTitle: "Rename"
            ) { label in
                version.label = label
                version.updatedAt = .now
            }
        }
    }

    private var selectedVersion: CVVersion? {
        guard let selection else { return nil }
        return version(in: [selection])
    }

    private func version(in ids: Set<CVVersion.ID>) -> CVVersion? {
        guard ids.count == 1, let id = ids.first else { return nil }
        return cvs.lazy.flatMap { $0.versions ?? [] }.first { $0.id == id }
    }

    private func createCV(named name: String) {
        let cv = CurriculumVitae(name: name)
        modelContext.insert(cv)
        let version = cv.addVersion()
        try? modelContext.save()
        selection = version.id
    }

    private func addVersion(to cv: CurriculumVitae?, copying source: CVVersion?) {
        guard let cv else { return }
        let version = cv.addVersion(copying: source)
        try? modelContext.save()
        selection = version.id
    }

    private func open(_ version: CVVersion) {
        try? modelContext.save()
        openWindow(id: WindowID.cv, value: version.persistentModelID)
    }

    private func delete(_ version: CVVersion) {
        if selection == version.id { selection = nil }
        version.cv?.updatedAt = .now
        modelContext.delete(version)
    }

    private func delete(_ cv: CurriculumVitae) {
        if let selectedVersion, selectedVersion.cv == cv { selection = nil }
        modelContext.delete(cv)
    }
}

private enum NameSheet: Identifiable {
    case newCV
    case renameCV(CurriculumVitae)
    case renameVersion(CVVersion)

    var id: AnyHashable {
        switch self {
        case .newCV: AnyHashable("new")
        case .renameCV(let cv): AnyHashable(cv.persistentModelID)
        case .renameVersion(let version): AnyHashable(version.persistentModelID)
        }
    }
}

private struct CVHeader: View {
    let cv: CurriculumVitae

    var body: some View {
        let count = cv.versions?.count ?? 0
        HStack {
            Text(cv.name)
            Spacer()
            Text(count == 1 ? "1 version" : "\(count) versions")
                .foregroundStyle(.secondary)
        }
    }
}

private struct CVVersionRow: View {
    let version: CVVersion

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(version.label)
                Text("Edited \(version.updatedAt, format: .relative(presentation: .named))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let fileName = version.htmlFileName {
                Label(fileName, systemImage: "doc.richtext")
                    .foregroundStyle(.secondary)
            } else {
                Text("No document")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        CVLibraryView()
    }
    .modelContainer(PreviewData.container)
    .frame(width: 700, height: 400)
}
#endif
