#if DEBUG
import SwiftUI
import SwiftData

struct ScreenshotData: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        let container = try ModelContainer(
            for: JobApplication.self, DocumentAsset.self, CurriculumVitae.self, CVVersion.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let year = Calendar.current.currentYear

        let applications: [(String, String, Int, Int, ApplicationStatus, Bool)] = [
            ("Northwind Labs", "iOS Developer", 11, 18, .interview, true),
            ("Seenland Digital", "Software Developer", 11, 4, .applied, true),
            ("Alpine Software", "Junior .NET Developer", 10, 21, .offer, true),
            ("Drautal Systems", "macOS Engineer", 10, 2, .applied, false),
            ("Karawanken Cloud", "Backend Developer", 9, 15, .rejected, true),
            ("Lakeside Studio", "Frontend Developer", 8, 27, .interview, false),
            ("Wörthersee Tech", "Mobile Developer", 7, 9, .withdrawn, false)
        ]
        for (company, title, month, day, status, hasDocument) in applications {
            let application = JobApplication(
                company: company,
                jobTitle: title,
                appliedOn: date(year, month, day),
                status: status
            )
            context.insert(application)
            if hasDocument {
                application.attachDocument(
                    content: coverLetter(company: company, jobTitle: title),
                    fileName: HTMLTemplate.fileName(for: company)
                )
            }
        }
        for (company, title, month) in [("Villach Robotics", "Embedded Developer", 11), ("Klagenfurt Data", "Data Engineer", 6)] {
            context.insert(JobApplication(company: company, jobTitle: title, appliedOn: date(year - 1, month, 12), status: .rejected))
        }

        let developerCV = CurriculumVitae(name: "Software Developer CV")
        context.insert(developerCV)
        let base = developerCV.addVersion()
        base.label = "General"
        base.attachDocument(content: HTMLTemplate.cv(name: "Alex Example"), fileName: "software-developer-cv.html")
        developerCV.addVersion(copying: base).label = "iOS focus"
        developerCV.addVersion(copying: base).label = "Backend focus"

        let germanCV = CurriculumVitae(name: "Lebenslauf (Deutsch)")
        context.insert(germanCV)
        germanCV.addVersion().attachDocument(content: HTMLTemplate.cv(name: "Alex Example"), fileName: "lebenslauf.html")

        try context.save()
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? .now
    }

    private static func coverLetter(company: String, jobTitle: String) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <title>\(jobTitle) – \(company)</title>
          <style>
            body {
              font-family: -apple-system, "Helvetica Neue", Arial, sans-serif;
              max-width: 640px;
              margin: 40px auto;
              padding: 0 24px;
              line-height: 1.6;
              color: #1d1d1f;
            }
            header {
              border-left: 4px solid #1e4fd8;
              padding-left: 16px;
              margin-bottom: 32px;
            }
            h1 {
              margin: 0;
              font-size: 28px;
            }
            .role {
              color: #1e4fd8;
              font-weight: 600;
            }
          </style>
        </head>
        <body>
          <header>
            <h1>Alex Example</h1>
            <p class="role">Application for \(jobTitle)</p>
          </header>
          <p>Dear \(company) team,</p>
          <p>
            I am excited to apply for the position of \(jobTitle). Building thoughtful,
            native apps is what I enjoy most, and your products are a great example of that.
          </p>
          <p>
            In my recent projects I designed SwiftUI interfaces, worked with SwiftData
            and shipped features from the first sketch to the release.
          </p>
          <p>I look forward to hearing from you.</p>
          <p>Kind regards,<br>Alex Example</p>
        </body>
        </html>
        """
    }
}

private struct ScreenshotWindow: View {
    let selection: SidebarItem

    @Query private var applications: [JobApplication]
    @Query private var cvs: [CurriculumVitae]

    var body: some View {
        let counts = Dictionary(grouping: applications, by: \.year).mapValues(\.count)

        NavigationSplitView {
            YearSidebarView(
                years: counts.keys.sorted(by: >),
                counts: counts,
                cvCount: cvs.count,
                selection: .constant(selection)
            )
        } detail: {
            switch selection {
            case .year(let year):
                ApplicationTableView(year: year)
            case .cvs:
                CVLibraryView()
            }
        }
        .frame(width: 1100, height: 520)
    }
}

#Preview("Applications", traits: .modifier(ScreenshotData())) {
    ScreenshotWindow(selection: .year(Calendar.current.currentYear))
}

#Preview("CVs", traits: .modifier(ScreenshotData())) {
    ScreenshotWindow(selection: .cvs)
}
#endif
