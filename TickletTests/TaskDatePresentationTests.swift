import Foundation
import Testing
@testable import Ticklet

struct TaskDatePresentationTests {
    @Test func badgeTextUsesRelativeLabels() {
        let calendar = Self.testCalendar
        let now = Self.date(2026, 3, 8, 9)

        #expect(
            TaskDatePresentation.badgeText(for: now, calendar: calendar, now: now) == "今日"
        )
        #expect(
            TaskDatePresentation.badgeText(
                for: calendar.date(byAdding: .day, value: 1, to: now)!,
                calendar: calendar,
                now: now
            ) == "明日"
        )
        #expect(
            TaskDatePresentation.badgeText(
                for: calendar.date(byAdding: .day, value: -1, to: now)!,
                calendar: calendar,
                now: now
            ) == "昨日"
        )
    }

    @Test func badgeTextFormatsRegularDates() {
        let calendar = Self.testCalendar
        let now = Self.date(2026, 3, 8, 9)
        let future = Self.date(2026, 4, 3, 12)

        #expect(
            TaskDatePresentation.badgeText(for: future, calendar: calendar, now: now) == "4月3日"
        )
    }

    @Test func badgeStyleClassifiesDates() {
        let calendar = Self.testCalendar
        let now = Self.date(2026, 3, 8, 9)

        #expect(
            TaskDatePresentation.badgeStyle(
                for: calendar.date(byAdding: .day, value: -1, to: now)!,
                calendar: calendar,
                now: now
            ) == .overdue
        )
        #expect(
            TaskDatePresentation.badgeStyle(for: now, calendar: calendar, now: now) == .today
        )
        #expect(
            TaskDatePresentation.badgeStyle(
                for: calendar.date(byAdding: .day, value: 2, to: now)!,
                calendar: calendar,
                now: now
            ) == .normal
        )
    }

    @Test func sectionTitleFormatsUpcomingDate() {
        let calendar = Self.testCalendar
        let upcoming = calendar.startOfDay(for: Self.date(2026, 3, 11, 15))

        #expect(
            TaskDatePresentation.sectionTitle(for: .upcoming(upcoming), calendar: calendar) == "3月11日(水)"
        )
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
