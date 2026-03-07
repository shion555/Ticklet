import Foundation
import Testing
@testable import Ticklet

struct TaskQueryServiceTests {
    @Test func selectedListAndSortUseSelectedListID() {
        let first = TaskList(name: "First", sortOrder: 1)
        let second = TaskList(name: "Second", sortOrder: 0)
        first.sort = .title

        let selected = TaskQueryService.selectedList(from: [second, first], selectedListID: first.id)

        #expect(selected?.id == first.id)
        #expect(TaskQueryService.selectedSort(from: selected) == .title)
        #expect(TaskQueryService.selectedSort(from: nil) == .manual)
    }

    @Test func sortedListsAndNextSortOrderArePureHelpers() {
        let first = TaskList(name: "First", sortOrder: 3)
        let second = TaskList(name: "Second", sortOrder: 1)
        let third = TaskList(name: "Third", sortOrder: 2)
        let tasks = [
            Self.makeTask(title: "one", sortOrder: 4),
            Self.makeTask(title: "two", sortOrder: 1)
        ]

        #expect(TaskQueryService.sortedLists([first, second, third]).map(\.name) == ["Second", "Third", "First"])
        #expect(TaskQueryService.nextSortOrder(for: tasks) == 5)
        #expect(TaskQueryService.nextSortOrder(for: []) == 0)
    }

    @Test func activeTasksForAllFilterUsesSelectedListAndTopLevelOnly() {
        let listA = TaskList(name: "A")
        let listB = TaskList(name: "B")
        let expected = makeTask(title: "match", list: listA, sortOrder: 2)
        let completed = makeTask(title: "completed", list: listA, isCompleted: true)
        let otherList = makeTask(title: "other", list: listB)
        let subtask = makeTask(title: "sub", list: listA, parentID: UUID())

        let result = TaskQueryService.activeTasks(
            from: [otherList, completed, subtask, expected],
            selectedListID: listA.id,
            filterMode: .all,
            sortOption: .manual
        )

        #expect(result.map(\.title) == ["match"])
    }

    @Test func activeTasksForStarredFilterIgnoresSelectedList() {
        let listA = TaskList(name: "A")
        let listB = TaskList(name: "B")
        let starredA = makeTask(title: "b", list: listA, isStarred: true)
        let starredB = makeTask(title: "a", list: listB, isStarred: true)
        let plain = makeTask(title: "plain", list: listA)

        let result = TaskQueryService.activeTasks(
            from: [starredA, plain, starredB],
            selectedListID: listA.id,
            filterMode: .starred,
            sortOption: .title
        )

        #expect(result.map(\.title) == ["a", "b"])
    }

    @Test func completedTasksOnlyReturnsMatchingTopLevelTasks() {
        let list = TaskList(name: "A")
        let match = makeTask(title: "match", list: list, isCompleted: true, isStarred: true)
        let active = makeTask(title: "active", list: list)
        let subtask = makeTask(title: "sub", list: list, isCompleted: true, parentID: UUID())

        let allResult = TaskQueryService.completedTasks(
            from: [match, active, subtask],
            selectedListID: list.id,
            filterMode: .all
        )
        let starredResult = TaskQueryService.completedTasks(
            from: [match, active, subtask],
            selectedListID: nil,
            filterMode: .starred
        )

        #expect(allResult.map(\.title) == ["match"])
        #expect(starredResult.map(\.title) == ["match"])
    }

    @Test func sortSupportsAllModes() {
        let early = Self.makeTask(
            title: "Bravo",
            createdAt: Self.date(2026, 3, 7, 9),
            dueDate: Self.date(2026, 3, 9, 0),
            sortOrder: 2
        )
        let late = Self.makeTask(
            title: "Alpha",
            createdAt: Self.date(2026, 3, 8, 9),
            dueDate: nil,
            sortOrder: 1
        )
        let dueSoon = Self.makeTask(
            title: "Charlie",
            createdAt: Self.date(2026, 3, 6, 9),
            dueDate: Self.date(2026, 3, 8, 0),
            sortOrder: 3
        )

        #expect(TaskQueryService.sort([early, late, dueSoon], by: .manual).map(\.title) == ["Alpha", "Bravo", "Charlie"])
        #expect(TaskQueryService.sort([early, late, dueSoon], by: .date).map(\.title) == ["Alpha", "Bravo", "Charlie"])
        #expect(TaskQueryService.sort([early, late, dueSoon], by: .dueDate).map(\.title) == ["Charlie", "Bravo", "Alpha"])
        #expect(TaskQueryService.sort([early, late, dueSoon], by: .title).map(\.title) == ["Alpha", "Bravo", "Charlie"])
    }

    @Test func groupedByDateKeepsSectionOrder() {
        let calendar = Self.testCalendar
        let now = Self.date(2026, 3, 8, 9)
        let tasks = [
            Self.makeTask(title: "noDue", dueDate: nil),
            Self.makeTask(title: "tomorrow", dueDate: Self.date(2026, 3, 9, 8)),
            Self.makeTask(title: "today", dueDate: Self.date(2026, 3, 8, 10)),
            Self.makeTask(title: "overdue", dueDate: Self.date(2026, 3, 7, 10)),
            Self.makeTask(title: "upcoming", dueDate: Self.date(2026, 3, 12, 10))
        ]

        let grouped = TaskQueryService.groupedByDate(tasks, calendar: calendar, now: now)

        #expect(grouped.map(\.section) == [
            .overdue,
            .today,
            .tomorrow,
            .upcoming(calendar.startOfDay(for: Self.date(2026, 3, 12, 10))),
            .noDueDate,
        ])
        #expect(grouped.map { $0.tasks.map(\.title) } == [["overdue"], ["today"], ["tomorrow"], ["upcoming"], ["noDue"]])
    }

    private static var testCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private static func makeTask(
        title: String,
        createdAt: Date = Date(timeIntervalSince1970: 0),
        dueDate: Date? = nil,
        sortOrder: Int = 0
    ) -> TaskItem {
        let task = TaskItem(title: title, dueDate: dueDate, sortOrder: sortOrder)
        task.createdAt = createdAt
        return task
    }

    private func makeTask(
        title: String,
        list: TaskList? = nil,
        isCompleted: Bool = false,
        isStarred: Bool = false,
        parentID: UUID? = nil,
        sortOrder: Int = 0
    ) -> TaskItem {
        let task = TaskItem(title: title, sortOrder: sortOrder, list: list, parentID: parentID)
        task.isCompleted = isCompleted
        task.isStarred = isStarred
        return task
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
