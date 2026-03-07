import Foundation

struct RecurrenceHelper {
    static func nextDate(from date: Date?, rule: RecurrenceRule) -> Date {
        let base = date ?? Date()
        let cal = Calendar.current
        switch rule {
        case .daily:
            return cal.date(byAdding: .day, value: 1, to: base) ?? base
        case .weekly:
            return cal.date(byAdding: .weekOfYear, value: 1, to: base) ?? base
        case .monthly:
            return cal.date(byAdding: .month, value: 1, to: base) ?? base
        case .yearly:
            return cal.date(byAdding: .year, value: 1, to: base) ?? base
        }
    }
}
