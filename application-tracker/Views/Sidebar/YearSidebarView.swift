import SwiftUI

enum SidebarItem: Hashable {
    case year(Int)
    case cvs
}

struct YearSidebarView: View {
    let years: [Int]
    let counts: [Int: Int]
    let cvCount: Int
    @Binding var selection: SidebarItem?

    var body: some View {
        List(selection: $selection) {
            Section("Years") {
                ForEach(years, id: \.self) { year in
                    Label(String(year), systemImage: "calendar")
                        .badge(counts[year] ?? 0)
                        .tag(SidebarItem.year(year))
                }
            }

            Section("Library") {
                Label("CVs", systemImage: "person.text.rectangle")
                    .badge(cvCount)
                    .tag(SidebarItem.cvs)
            }
        }
        .navigationSplitViewColumnWidth(min: 160, ideal: 180)
    }
}

#Preview {
    YearSidebarView(
        years: [2026, 2025],
        counts: [2026: 4, 2025: 1],
        cvCount: 2,
        selection: .constant(.year(2026))
    )
    .frame(width: 200, height: 300)
}
