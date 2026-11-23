//
//  ApplicationTableView.swift
//  application-tracker
//
//  Created by Moritz Gutschi on 23.11.26.
//

import SwiftUI
import SwiftData

import SwiftUI
import SwiftData

struct ApplicationTableView: View {
    let year: Int

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Query private var applications: [JobApplication]

    @State private var selection = Set<JobApplication.ID>()
    @State private var sortOrder = [KeyPathComparator(\JobApplication.appliedOn, order: .reverse)]
    @State private var formSheet: FormSheet?

    init(year: Int) {
        self.year = year

        let interval = Calendar.current.interval(ofYear: year)
        let start = interval.start
        let end = interval.end
        _applications = Query(filter: #Predicate<JobApplication> { application in
            application.appliedOn >= start && application.appliedOn < end
        })
    }

    private var sortedApplications: [JobApplication] {
        applications.sorted(using: sortOrder)
    }

    var body: some View {
        Table(sortedApplications, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Company", value: \.company)

            TableColumn("Job Title", value: \.jobTitle)

            TableColumn("Date", value: \.appliedOn) { application in
                Text(application.appliedOn, format: .dateTime.day().month().year())
            }
            .width(min: 90, ideal: 110)

            TableColumn("Status", value: \.status) { application in
                StatusBadge(status: application.status)
            }
            .width(min: 100, ideal: 120)

            TableColumn("Document") { application in
                if let fileName = application.htmlFileName {
                    Label(fileName, systemImage: "doc.richtext")
                } else {
                    Text("—").foregroundStyle(.secondary)
                }
            }
            .width(min: 80, ideal: 140)
        }
        .contextMenu(forSelectionType: JobApplication.ID.self) { ids in
            if let application = singleApplication(in: ids) {
                Button("Open Document") { openDocument(of: application) }
                Button("Edit Details…") { formSheet = .edit(application) }
                Divider()
            }
            if !ids.isEmpty {
                Button("Delete", role: .destructive) { delete(ids) }
            }
        } primaryAction: { ids in
            if let application = singleApplication(in: ids) {
                openDocument(of: application)
            }
        }
        .onDeleteCommand { delete(selection) }
        .overlay {
            if applications.isEmpty {
                ContentUnavailableView {
                    Label("No applications in \(String(year))", systemImage: "tray")
                } description: {
                    Text("Add your first one with the + button.")
                } actions: {
                    Button("New Application") { formSheet = .add }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    formSheet = .add
                } label: {
                    Label("New Application", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
                .help("New Application (⌘N)")

                Button {
                    if let application = singleApplication(in: selection) {
                        openDocument(of: application)
                    }
                } label: {
                    Label("Open Document", systemImage: "doc.richtext")
                }
                .disabled(selection.count != 1)
                .help("Open the document window (double-click a row)")

                Button {
                    if let application = singleApplication(in: selection) {
                        formSheet = .edit(application)
                    }
                } label: {
                    Label("Edit Details", systemImage: "pencil")
                }
                .disabled(selection.count != 1)
                .help("Edit company, title, date and status")

                Button(role: .destructive) {
                    delete(selection)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(selection.isEmpty)
                .help("Delete the selected applications (⌘Z to undo)")
            }
        }
        .navigationTitle(String(year))
        .navigationSubtitle(applications.count == 1 ? "1 application" : "\(applications.count) applications")
        .sheet(item: $formSheet) { sheet in
            switch sheet {
            case .add:
                ApplicationFormView(defaultYear: year)
            case .edit(let application):
                ApplicationFormView(application: application, defaultYear: year)
            }
        }
    }

    private func singleApplication(in ids: Set<JobApplication.ID>) -> JobApplication? {
        guard ids.count == 1, let id = ids.first else { return nil }
        return applications.first { $0.id == id }
    }

    private func openDocument(of application: JobApplication) {
        try? modelContext.save()
        openWindow(id: WindowID.document, value: application.persistentModelID)
    }

    private func delete(_ ids: Set<JobApplication.ID>) {
        for application in applications where ids.contains(application.id) {
            modelContext.delete(application)
        }
        selection.subtract(ids)
    }
}

private enum FormSheet: Identifiable {
    case add
    case edit(JobApplication)

    var id: AnyHashable {
        switch self {
        case .add: AnyHashable("add")
        case .edit(let application): AnyHashable(application.persistentModelID)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ApplicationTableView(year: Calendar.current.currentYear)
    }
    .modelContainer(PreviewData.container)
    .frame(width: 800, height: 400)
}
#endif
