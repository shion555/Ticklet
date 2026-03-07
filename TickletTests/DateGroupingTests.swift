import Foundation
import Testing
@testable import Ticklet

struct DateGroupingTests {
    @Test func sectionClassifiesDates() {
        let calendar = Self.testCalendar
        let now = Self.date(2026, 3, 8, 9)

        #expect(DateSection.section(for: nil, calendar: calendar, now: now) == .noDueDate)
        #expect(
            DateSection.section(
                for: calendar.date(byAdding: .day, value: -1, to: now)!,
                calendar: calendar,
                now: now
            ) == .overdue
        )
        #expect(DateSection.section(for: now, calendar: calendar, now: now) == .today)
        #expect(
            DateSection.section(
                for: calendar.date(byAdding: .day, value: 1, to: now)!,
                calendar: calendar,
                now: now
            ) == .tomorrow
        )

        let later = Self.date(2026, 3, 12, 15)
        #expect(
            DateSection.section(for: later, calendar: calendar, now: now)
                == .upcoming(calendar.startOfDay(for: later))
        )
    }

    @Test func sectionsSortInDisplayOrder() {
        let calendar = Self.testCalendar
        let upcoming = calendar.startOfDay(for: Self.date(2026, 3, 12, 12))
        let ordered: [DateSection] = [.noDueDate, .upcoming(upcoming), .tomorrow, .today, .overdue]

        #expect(ordered.sorted() == [.overdue, .today, .tomorrow, .upcoming(upcoming), .noDueDate])
    }

    private static var testCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int) -> Date {
        let components = DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day,
            hour: hour
        )
        return testCalendar.date(from: components)!
    }
}
