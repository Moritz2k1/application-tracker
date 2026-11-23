import SwiftUI

extension ApplicationStatus {
    var color: Color {
        switch self {
        case .draft: .gray
        case .applied: .accentColor
        case .interview: .brandOrange
        case .offer: .green
        case .rejected: .red
        case .withdrawn: .secondary
        }
    }
}

struct StatusBadge: View {
    let status: ApplicationStatus

    var body: some View {
        Label(status.label, systemImage: status.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(status.color.opacity(0.14), in: Capsule())
            .overlay(Capsule().strokeBorder(status.color.opacity(0.25), lineWidth: 0.5))
    }
}

#Preview {
    VStack(alignment: .leading) {
        ForEach(ApplicationStatus.allCases) { StatusBadge(status: $0) }
    }
    .padding()
}
