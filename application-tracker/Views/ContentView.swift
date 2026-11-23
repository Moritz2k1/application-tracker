//
//  ContentView.swift
//  application-tracker
//
//  Created by Moritz Gutschi on 23.11.26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.undoManager) private var undoManager

    @Query private var allApplications: [JobApplication]
    @State private var selectedYear: Int? = Calendar.current.currentYear

    var body: some View {
        let counts = Dictionary(grouping: allApplications, by: \.year).mapValues(\.count)

        NavigationSplitView {
            YearSidebarView(years: years(from: counts), counts: counts, selection: $selectedYear)
        } detail: {
            if let year = selectedYear {
                ApplicationTableView(year: year)
                    .id(year)
            } else {
                ContentUnavailableView("Select a year", systemImage: "calendar")
            }
        }
        .onChange(of: undoManager, initial: true) {
            modelContext.undoManager = undoManager
        }
    }

    private func years(from counts: [Int: Int]) -> [Int] {
        var years = Set(counts.keys)
        years.insert(Calendar.current.currentYear)
        return years.sorted(by: >)
    }
}

#if DEBUG
#Preview {
    ContentView()
        .modelContainer(PreviewData.container)
        .frame(width: 900, height: 500)
}
#endif
