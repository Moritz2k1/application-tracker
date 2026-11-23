import SwiftUI

struct ApplicationSummaryView: View {
    let applications: [JobApplication]

    private func count(_ statuses: Set<ApplicationStatus>) -> Int {
        applications.filter { statuses.contains($0.status) }.count
    }

    var body: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Total",
                value: applications.count,
                systemImage: "tray.full.fill",
                isHighlighted: true
            )
            SummaryCard(
                title: "Active",
                value: count([.applied, .interview]),
                systemImage: "paperplane.fill",
                tint: .brandDeep
            )
            SummaryCard(
                title: "Interviews",
                value: count([.interview]),
                systemImage: "person.2.fill",
                tint: .brandOrange
            )
            SummaryCard(
                title: "Offers",
                value: count([.offer]),
                systemImage: "checkmark.seal.fill",
                tint: .green
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct SummaryCard: View {
    let title: String
    let value: Int
    let systemImage: String
    var tint: Color = .brandDeep
    var isHighlighted = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isHighlighted ? Color.brandDeep : .white)
                .frame(width: 32, height: 32)
                .background(
                    isHighlighted ? AnyShapeStyle(.white.opacity(0.9)) : AnyShapeStyle(tint.gradient),
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 0) {
                Text(value, format: .number)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .contentTransition(.numericText())
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isHighlighted ? AnyShapeStyle(.white.opacity(0.85)) : AnyShapeStyle(.secondary))
            }
            .foregroundStyle(isHighlighted ? .white : .primary)

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isHighlighted ? AnyShapeStyle(LinearGradient.brand) : AnyShapeStyle(.background.secondary))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.separator.opacity(isHighlighted ? 0 : 0.6), lineWidth: 0.5)
        }
        .shadow(color: isHighlighted ? .brandDeep.opacity(0.25) : .clear, radius: 8, y: 4)
        .animation(.snappy, value: value)
    }
}
