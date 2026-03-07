import Foundation

enum DateSection: Hashable, Comparable {
    case overdue
    case today
    case tomorrow
    case upcoming(Date)
    case noDueDate

    private var sortKey: Int {
        switch self {
        case .overdue: return 0
        case .today: return 1
        case .tomorrow: return 2
        case .upcoming: return 3
        case .noDueDate: return 4
        }
    }

    static func < (lhs: DateSection, rhs: DateSection) -> Bool {
        if lhs.sortKey != rhs.sortKey { return lhs.sortKey < rhs.sortKey }
        if case .upcoming(let d1) = lhs, case .upcoming(let d2) = rhs {
            return d1 < d2
        }
        return false
    }

    static func section(
        for date: Date?,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> DateSection {
        guard let date = date else { return .noDueDate }
        let today = calendar.startOfDay(for: now)
        let taskDay = calendar.startOfDay(for: date)

        if taskDay < today { return .overdue }
        if calendar.isDate(date, inSameDayAs: now) { return .today }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return .tomorrow
        }
        return .upcoming(taskDay)
    }
}
