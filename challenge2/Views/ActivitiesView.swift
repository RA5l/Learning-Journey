import SwiftUI

struct ActivitiesView: View {
    @State private var viewModel: ActivitiesViewModel
    @State private var scrolledMonth: Date?

    init(store: ProgressStore) {
        let viewModel = ActivitiesViewModel(store: store)
        _viewModel = State(initialValue: viewModel)
        _scrolledMonth = State(initialValue: viewModel.currentMonthID)
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        let symbols = viewModel.weekdaySymbols

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(viewModel.months) { month in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(month.title)
                            .font(.headline)

                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(symbols, id: \.self) { symbol in
                                Text(symbol)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            ForEach(0..<month.leadingBlanks, id: \.self) { _ in
                                Color.clear.frame(height: 1)
                            }

                            ForEach(month.days) { day in
                                DayCircleView(day: day, size: 40)
                            }
                        }

                        Divider()
                    }
                    .id(month.id)
                }
            }
            .scrollTargetLayout()
            .padding()
        }
        .scrollPosition(id: $scrolledMonth, anchor: .top)
        .navigationTitle("Activities")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Calendar history") {
    NavigationStack { ActivitiesView(store: .preview(.richHistory)) }
}
