import SwiftUI

struct YearSidebarView: View {
    let years: [Int]
    let counts: [Int: Int]
    @Binding var selection: Int?

    var body: some View {
        List(selection: $selection) {
            Section("Years") {
                ForEach(years, id: \.self) { year in
                    Label(String(year), systemImage: "calendar")
                        .badge(counts[year] ?? 0)
                }
            }
        }
        .navigationSplitViewColumnWidth(min: 160, ideal: 180)
    }
}

#Preview {
    YearSidebarView(years: [2026, 2025], counts: [2026: 4, 2025: 1], selection: .constant(2026))
        .frame(width: 200, height: 300)
}
