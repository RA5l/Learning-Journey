import Foundation

struct CalendarDay: Identifiable {
    let date: Date
    let number: Int
    let status: Day.DayStatus?
    let isToday: Bool

    var id: Date { date }

    init(date: Date, statuses: [Date: Day.DayStatus], now: Date, calendar: Calendar) {
        self.date = date
        number = calendar.component(.day, from: date)
        status = statuses[calendar.startOfDay(for: date)]
        isToday = calendar.isDate(date, inSameDayAs: now)
    }
}
