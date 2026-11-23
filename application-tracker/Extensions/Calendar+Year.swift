import Foundation

extension Calendar {
    var currentYear: Int {
        component(.year, from: .now)
    }

    func interval(ofYear year: Int) -> DateInterval {
        let start = date(from: DateComponents(year: year, month: 1, day: 1)) ?? .now
        let end = date(byAdding: .year, value: 1, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    func today(inYear year: Int) -> Date {
        var components = dateComponents([.year, .month, .day], from: .now)
        components.year = year
        return date(from: components) ?? .now
    }
}
