import SwiftUI

struct WeekStripView: View {
    let symbols: [String]
    let days: [CalendarDay]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days.indices, id: \.self) { index in
                VStack(spacing: 8) {
                    Text(symbols[index])
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .accessibilityHidden(true)
                    DayCircleView(day: days[index])
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
