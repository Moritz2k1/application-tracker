import SwiftUI
import SwiftData

struct ApplicationFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let application: JobApplication?

    @State private var company: String
    @State private var jobTitle: String
    @State private var appliedOn: Date
    @State private var status: ApplicationStatus
    @State private var notes: String

    init(application: JobApplication? = nil, defaultYear: Int = Calendar.current.currentYear) {
        self.application = application
        _company = State(initialValue: application?.company ?? "")
        _jobTitle = State(initialValue: application?.jobTitle ?? "")
        _appliedOn = State(initialValue: application?.appliedOn ?? Calendar.current.today(inYear: defaultYear))
        _status = State(initialValue: application?.status ?? .applied)
        _notes = State(initialValue: application?.notes ?? "")
    }

    private var isEditing: Bool { application != nil }

    private var isValid: Bool {
        !company.trimmed.isEmpty && !jobTitle.trimmed.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField("Company", text: $company)
                    TextField("Job title", text: $jobTitle)
                } header: {
                    Text(isEditing ? "Edit Application" : "New Application")
                        .font(.headline)
                }

                Section {
                    DatePicker("Applied on", selection: $appliedOn, displayedComponents: .date)
                    Picker("Status", selection: $status) {
                        ForEach(ApplicationStatus.allCases) { status in
                            Label(status.label, systemImage: status.systemImage)
                                .tag(status)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                        .labelsHidden()
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(isEditing ? "Save" : "Add") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 460, height: 440)
    }

    private func save() {
        let trimmedCompany = company.trimmed
        let trimmedJobTitle = jobTitle.trimmed

        if let application {
            application.company = trimmedCompany
            application.jobTitle = trimmedJobTitle
            application.appliedOn = appliedOn
            application.status = status
            application.notes = notes
            application.updatedAt = .now
        } else {
            let newApplication = JobApplication(
                company: trimmedCompany,
                jobTitle: trimmedJobTitle,
                appliedOn: appliedOn,
                status: status,
                notes: notes
            )
            modelContext.insert(newApplication)
            try? modelContext.save()
        }
        dismiss()
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

#if DEBUG
#Preview("New") {
    ApplicationFormView()
        .modelContainer(PreviewData.container)
}
#endif
