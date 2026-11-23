#if DEBUG
import Foundation
import SwiftData

@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        do {
            let container = try ModelContainer(
                for: JobApplication.self, DocumentAsset.self, CurriculumVitae.self, CVVersion.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            samples.forEach { container.mainContext.insert($0) }
            return container
        } catch {
            fatalError("Could not create preview container: \(error)")
        }
    }()

    private static var samples: [JobApplication] {
        let thisYear = Calendar.current.currentYear
        return [
            JobApplication(company: "Alpine Software GmbH", jobTitle: "Junior .NET Developer",
                           appliedOn: date(thisYear, 3, 12), status: .rejected),
            JobApplication(company: "Seenland Digital", jobTitle: "Software Developer (30 h)",
                           appliedOn: date(thisYear, 9, 4), status: .interview,
                           notes: "Second interview on site"),
            JobApplication(company: "Drautal Systems", jobTitle: "iOS/macOS Developer",
                           appliedOn: date(thisYear, 10, 20), status: .applied),
            JobApplication(company: "Karawanken Labs", jobTitle: "Working Student Backend",
                           appliedOn: date(thisYear - 1, 11, 2), status: .withdrawn),
        ]
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }
}
#endif
