import SwiftUI

extension Color {
    nonisolated static let brandDeep = Color(red: 0x1E / 255, green: 0x4F / 255, blue: 0xD8 / 255)
    nonisolated static let brandSky = Color(red: 0x4F / 255, green: 0xA8 / 255, blue: 0xFF / 255)
    nonisolated static let brandOrange = Color(red: 0xFF / 255, green: 0x9F / 255, blue: 0x0A / 255)
}

extension LinearGradient {
    nonisolated static let brand = LinearGradient(
        colors: [.brandDeep, .brandSky],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct IconTile: View {
    let systemImage: String
    var size: CGFloat = 28
    var gradient: LinearGradient = .brand

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(gradient, in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
    }
}

struct MonogramTile: View {
    let text: String
    var size: CGFloat = 24

    private var initial: String {
        text.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "?"
    }

    private var gradient: LinearGradient {
        let palettes: [[Color]] = [
            [.brandDeep, .brandSky],
            [.brandSky, .brandDeep],
            [.brandDeep, .indigo],
            [.brandOrange, .orange],
            [.teal, .brandSky]
        ]
        let index = text.unicodeScalars.reduce(0) { ($0 + Int($1.value)) % palettes.count }
        return LinearGradient(colors: palettes[index], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        Text(initial)
            .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(gradient, in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
    }
}

struct BrandEmptyState<Actions: View>: View {
    let title: String
    let message: String
    let systemImage: String
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        VStack(spacing: 16) {
            IconTile(systemImage: systemImage, size: 72)
                .shadow(color: .brandDeep.opacity(0.25), radius: 16, y: 8)

            VStack(spacing: 6) {
                Text(title)
                    .font(.title2.weight(.semibold))
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }

            HStack(spacing: 10) {
                actions()
            }
            .controlSize(.large)
            .padding(.top, 4)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    BrandEmptyState(
        title: "No applications yet",
        message: "Add your first application to start tracking.",
        systemImage: "paperplane.fill"
    ) {
        Button("New Application") { }
            .buttonStyle(.borderedProminent)
    }
    .frame(width: 600, height: 400)
}
