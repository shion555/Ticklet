import Foundation

enum DateSection: Hashable, Comparable {
    case overdue
    case today
    case tomorrow
    case upcoming(Date)
    case noDueDate

    var title: String {
        switch self {
        case .overdue: return "期限超過"
        case .today: return "今日"
        case .tomorrow: return "明日"
        case .upcoming(let date):
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日(E)"
            formatter.locale = Locale(identifier: "ja_JP")
            return formatter.string(from: date)
        case .noDueDate: return "期限なし"
        }
    }

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

    static func section(for date: Date?) -> DateSection {
        guard let date = date else { return .noDueDate }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let taskDay = cal.startOfDay(for: date)

        if taskDay < today { return .overdue }
        if cal.isDateInToday(date) { return .today }
        if cal.isDateInTomorrow(date) { return .tomorrow }
        return .upcoming(taskDay)
    }
}
