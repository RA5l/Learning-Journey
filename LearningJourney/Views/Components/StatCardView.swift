import SwiftUI

struct StatCardView: View {
    let systemImage: String
    let tint: Color
    let count: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
                .symbolEffect(.bounce, value: count)
                .accessibilityHidden(true)
            Text("^[\(count) day](inflect: true)")
                .font(.headline)
                .contentTransition(.numericText(value: Double(count)))
            Text(label)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .glassEffect(.regular, in: .rect(cornerRadius: 34))
        .accessibilityElement(children: .combine)
    }
}
