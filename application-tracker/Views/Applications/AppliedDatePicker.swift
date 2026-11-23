import SwiftUI

struct AppliedDatePicker: View {
    @Binding var date: Date

    @State private var isShowingCalendar = false

    private let calendar = Calendar.current

    private var shortcuts: [(title: String, date: Date)] {
        let today = calendar.startOfDay(for: .now)
        return [
            ("Today", today),
            ("Yesterday", calendar.date(byAdding: .day, value: -1, to: today) ?? today),
            ("1 week ago", calendar.date(byAdding: .day, value: -7, to: today) ?? today)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                isShowingCalendar.toggle()
            } label: {
                HStack(spacing: 12) {
                    CalendarTile(date: date)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Applied on")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(date, format: .dateTime.weekday(.wide).day().month(.wide).year())
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isShowingCalendar ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isShowingCalendar, arrowEdge: .bottom) {
                DatePicker("Applied on", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(.accentColor)
                    .padding()
                    .onChange(of: date) {
                        isShowingCalendar = false
                    }
            }
            .accessibilityLabel("Applied on")
            .accessibilityValue(Text(date, format: .dateTime.day().month(.wide).year()))

            HStack(spacing: 6) {
                ForEach(shortcuts, id: \.title) { shortcut in
                    let isSelected = calendar.isDate(date, inSameDayAs: shortcut.date)
                    Button(shortcut.title) {
                        withAnimation(.snappy) { date = shortcut.date }
                    }
                    .buttonStyle(.plain)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? Color.white : Color.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.accentColor.opacity(0.12)),
                        in: Capsule()
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CalendarTile: View {
    let date: Date

    var body: some View {
        VStack(spacing: 0) {
            Text(date, format: .dateTime.month(.abbreviated))
                .font(.system(size: 9, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
                .background(LinearGradient.brand)

            Text(date, format: .dateTime.day())
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentTransition(.numericText())
        }
        .frame(width: 40, height: 42)
        .background(.background, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(.separator, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
    }
}

#Preview {
    @Previewable @State var date = Date.now
    Form {
        AppliedDatePicker(date: $date)
    }
    .formStyle(.grouped)
    .frame(width: 460, height: 200)
}
