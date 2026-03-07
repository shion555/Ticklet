import Foundation

enum TaskDateBadgeStyle {
    case overdue
    case today
    case normal
}

enum TaskDatePresentation {
    static func badgeStyle(
        for date: Date,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> TaskDateBadgeStyle {
        let today = calendar.startOfDay(for: now)
        let taskDay = calendar.startOfDay(for: date)

        if taskDay < today {
            return .overdue
        }
        if calendar.isDate(date, inSameDayAs: now) {
            return .today
        }
        return .normal
    }

    static func badgeText(
        for date: Date,
        calendar: Calendar = .current,
        locale: Locale = Locale(identifier: "ja_JP"),
        now: Date = Date()
    ) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return "今日"
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return "明日"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "昨日"
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    static func sectionTitle(
        for section: DateSection,
        calendar: Calendar = .current,
        locale: Locale = Locale(identifier: "ja_JP")
    ) -> String {
        switch section {
        case .overdue:
            return "期限超過"
        case .today:
            return "今日"
        case .tomorrow:
            return "明日"
        case .upcoming(let date):
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.locale = locale
            formatter.timeZone = calendar.timeZone
            formatter.dateFormat = "M月d日(E)"
            return formatter.string(from: date)
        case .noDueDate:
            return "期限なし"
        }
    }
}
