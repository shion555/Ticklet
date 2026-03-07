import Foundation

struct RecurrenceHelper {
    static func nextDate(
        from date: Date?,
        rule: RecurrenceRule,
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) -> Date {
        let base = date ?? referenceDate
        switch rule {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: base) ?? base
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: base) ?? base
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: base) ?? base
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: base) ?? base
        }
    }
}
