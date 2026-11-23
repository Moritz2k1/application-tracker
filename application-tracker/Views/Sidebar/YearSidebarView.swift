import SwiftUI
import AppKit

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
            Section("Applications") {
                ForEach(years, id: \.self) { year in
                    Label(String(year), systemImage: "calendar")
                        .badge(counts[year] ?? 0)
                        .tag(SidebarItem.year(year))
                }
            }

            Section("Documents") {
                Label("CVs", systemImage: "person.text.rectangle")
                    .badge(cvCount)
                    .tag(SidebarItem.cvs)
            }
        }
        .safeAreaInset(edge: .top) {
            SidebarHeader()
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
    }
}

private struct SidebarHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 34, height: 34)
                .shadow(color: .brandDeep.opacity(0.25), radius: 4, y: 2)

            VStack(alignment: .leading, spacing: 0) {
                Text("Application")
                    .font(.headline)
                Text("Tracker")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(LinearGradient.brand)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

#Preview {
    YearSidebarView(
        years: [2026, 2025],
        counts: [2026: 4, 2025: 1],
        cvCount: 2,
        selection: .constant(.year(2026))
    )
    .frame(width: 220, height: 300)
}
