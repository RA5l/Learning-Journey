import SwiftUI

struct DayCircleView: View {
    let day: CalendarDay
    var size: CGFloat = 44

    var body: some View {
        Text(verbatim: "\(day.number)")
            .font(.title3.weight(.semibold))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(background, in: .circle)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(day.date, format: .dateTime.weekday(.wide).day().month(.wide)))
            .accessibilityValue(statusDescription)
            .accessibilityAddTraits(day.isToday ? .isSelected : [])
    }

    private var foreground: Color {
        switch day.status {
        case .learned: .learned
        case .frozen: .frozen
        case nil: day.isToday ? .white : .primary
        }
    }

    private var background: Color {
        switch day.status {
        case .learned: Color.learned.opacity(0.12)
        case .frozen: Color.frozen.opacity(0.15)
        case nil: day.isToday ? .learned : .clear
        }
    }

    private var statusDescription: String {
        switch day.status {
        case .learned: "Learned"
        case .frozen: "Frozen"
        case nil: ""
        }
    }
}
