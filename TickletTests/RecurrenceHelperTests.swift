import Foundation
import Testing
@testable import Ticklet

struct RecurrenceHelperTests {
    @Test func nextDateAdvancesForEachRule() {
        let calendar = Self.testCalendar
        let start = Self.date(2026, 3, 8)

        #expect(
            RecurrenceHelper.nextDate(from: start, rule: .daily, calendar: calendar) == Self.date(2026, 3, 9)
        )
        #expect(
            RecurrenceHelper.nextDate(from: start, rule: .weekly, calendar: calendar) == Self.date(2026, 3, 15)
        )
        #expect(
            RecurrenceHelper.nextDate(from: start, rule: .monthly, calendar: calendar) == Self.date(2026, 4, 8)
        )
        #expect(
            RecurrenceHelper.nextDate(from: start, rule: .yearly, calendar: calendar) == Self.date(2027, 3, 8)
        )
    }

    @Test func nextDateUsesReferenceDateWhenSourceIsNil() {
        let calendar = Self.testCalendar
        let referenceDate = Self.date(2026, 3, 8)

        #expect(
            RecurrenceHelper.nextDate(
                from: nil,
                rule: .daily,
                calendar: calendar,
                referenceDate: referenceDate
            ) == Self.date(2026, 3, 9)
        )
    }

    private static var testCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        let components = DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day
        )
        return testCalendar.date(from: components)!
    }
}
