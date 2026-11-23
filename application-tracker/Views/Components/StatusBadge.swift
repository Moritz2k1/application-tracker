import SwiftUI

extension ApplicationStatus {
    var color: Color {
        switch self {
        case .draft: .gray
        case .applied: .blue
        case .interview: .orange
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
            .font(.caption.weight(.medium))
            .foregroundStyle(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(status.color.opacity(0.15), in: Capsule())
    }
}

#Preview {
    VStack(alignment: .leading) {
        ForEach(ApplicationStatus.allCases) { StatusBadge(status: $0) }
    }
    .padding()
}
