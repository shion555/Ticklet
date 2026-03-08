import Foundation
import Testing
@testable import Ticklet

struct ContentViewProjectionTests {
    @Test func fallsBackWhenNoListIsSelected() {
        let projection = ContentViewProjection(
            lists: [],
            allTasks: [],
            selectedListID: nil,
            filterMode: .all
        )

        #expect(projection.selectedList == nil)
        #expect(projection.selectedListID == nil)
        #expect(projection.selectedListName == "マイタスク")
        #expect(projection.currentSort == .manual)
        #expect(projection.renameableSelectedList == nil)
    }

    @Test func unknownSelectedListFallsBackToDefaultPresentation() {
        let defaultList = TaskList(name: "Default", isDefault: true)
        defaultList.sort = .dueDate

        let projection = ContentViewProjection(
            lists: [defaultList],
            allTasks: [],
            selectedListID: UUID(),
            filterMode: .all
        )

        #expect(projection.selectedList == nil)
        #expect(projection.selectedListName == "マイタスク")
        #expect(projection.currentSort == .manual)
    }

    @Test func reflectsSelectedListMetadata() {
        let list = TaskList(name: "Work", sortOrder: 2)
        list.sort = .title

        let projection = ContentViewProjection(
            lists: [list],
            allTasks: [],
            selectedListID: list.id,
            filterMode: .all
        )

        #expect(projection.selectedList?.id == list.id)
        #expect(projection.selectedListName == "Work")
        #expect(projection.currentSort == .title)
        #expect(projection.renameableSelectedList?.id == list.id)
    }

    @Test func allFilterOnlyUsesSelectedListTopLevelIncompleteTasks() {
        let listA = TaskList(name: "A")
        let listB = TaskList(name: "B")
        let match = makeTask(title: "match", list: listA, sortOrder: 4)
        let completed = makeTask(title: "completed", list: listA, isCompleted: true)
        let subtask = makeTask(title: "subtask", list: listA, parentID: UUID())
        let otherList = makeTask(title: "other", list: listB)

        let projection = ContentViewProjection(
            lists: [listA, listB],
            allTasks: [match, completed, subtask, otherList],
            selectedListID: listA.id,
            filterMode: .all
        )

        #expect(projection.activeTasks.map(\.title) == ["match"])
        #expect(projection.completedTasks.map(\.title) == ["completed"])
        #expect(projection.nextSortOrder == 5)
    }

    @Test func starredFilterCrossesListsForActiveAndCompletedTasks() {
        let listA = TaskList(name: "A")
        let listB = TaskList(name: "B")
        let activeStarA = makeTask(title: "activeA", list: listA, isStarred: true)
        let activeStarB = makeTask(title: "activeB", list: listB, isStarred: true)
        let completedStar = makeTask(title: "done", list: listB, isCompleted: true, isStarred: true)
        let plain = makeTask(title: "plain", list: listA)

        let projection = ContentViewProjection(
            lists: [listA, listB],
            allTasks: [activeStarB, plain, completedStar, activeStarA],
            selectedListID: listA.id,
            filterMode: .starred
        )

        #expect(Set(projection.activeTasks.map(\.title)) == Set(["activeA", "activeB"]))
        #expect(projection.completedTasks.map(\.title) == ["done"])
    }

    @Test func starredCompletedTasksStillCrossListsWithoutSelection() {
        let listA = TaskList(name: "A")
        let listB = TaskList(name: "B")
        let completedStarA = makeTask(title: "doneA", list: listA, isCompleted: true, isStarred: true)
        let completedStarB = makeTask(title: "doneB", list: listB, isCompleted: true, isStarred: true)
        let completedPlain = makeTask(title: "plain", list: listA, isCompleted: true)

        let projection = ContentViewProjection(
            lists: [listA, listB],
            allTasks: [completedStarA, completedPlain, completedStarB],
            selectedListID: nil,
            filterMode: .starred
        )

        #expect(Set(projection.completedTasks.map(\.title)) == Set(["doneA", "doneB"]))
    }

    @Test func groupedActiveTasksAreEnabledForDateSorts() {
        let list = TaskList(name: "A")
        list.sort = .dueDate
        let task = Self.makeDatedTask(
            title: "upcoming",
            createdAt: Self.date(2026, 3, 8, 9),
            dueDate: Self.date(2026, 3, 10, 9),
            sortOrder: 1
        )
        task.list = list

        let projection = ContentViewProjection(
            lists: [list],
            allTasks: [task],
            selectedListID: list.id,
            filterMode: .all
        )

        #expect(projection.showsGroupedActiveTasks == true)
        #expect(projection.groupedActiveTasks.map(\.tasks).flatMap { $0 }.map(\.title) == ["upcoming"])
    }

    @Test func groupedActiveTasksKeepDateSectionOrder() {
        let list = TaskList(name: "A")
        list.sort = .date
        let tasks = [
            makeTask(title: "none", list: list),
            Self.makeLinkedTask(title: "today", list: list, createdAt: Self.date(2026, 3, 8, 8), dueDate: Self.date(2026, 3, 8, 10), sortOrder: 0),
            Self.makeLinkedTask(title: "later", list: list, createdAt: Self.date(2026, 3, 8, 9), dueDate: Self.date(2026, 3, 12, 10), sortOrder: 1),
        ]

        let projection = ContentViewProjection(
            lists: [list],
            allTasks: tasks,
            selectedListID: list.id,
            filterMode: .all,
            calendar: Self.testCalendar,
            now: Self.date(2026, 3, 8, 12)
        )

        #expect(projection.groupedActiveTasks.map(\.section) == [
            .today,
            .upcoming(Self.testCalendar.startOfDay(for: Self.date(2026, 3, 12, 10))),
            .noDueDate,
        ])
        #expect(projection.groupedActiveTasks.map { $0.tasks.map(\.title) } == [["today"], ["later"], ["none"]])
    }

    @Test func defaultListCannotBeRenamed() {
        let list = TaskList(name: "Default", isDefault: true)

        let projection = ContentViewProjection(
            lists: [list],
            allTasks: [],
            selectedListID: list.id,
            filterMode: .all
        )

        #expect(projection.renameableSelectedList == nil)
    }

    @Test func listsAreSortedBySortOrder() {
        let first = TaskList(name: "First", sortOrder: 2)
        let second = TaskList(name: "Second", sortOrder: 0)
        let third = TaskList(name: "Third", sortOrder: 1)

        let projection = ContentViewProjection(
            lists: [first, second, third],
            allTasks: [],
            selectedListID: nil,
            filterMode: .all
        )

        #expect(projection.sortedLists.map(\.name) == ["Second", "Third", "First"])
    }

    @Test func selectedListAndSortUseSelectedListID() {
        let first = TaskList(name: "First", sortOrder: 1)
        let second = TaskList(name: "Second", sortOrder: 0)
        first.sort = .title

        let projection = ContentViewProjection(
            lists: [second, first],
            allTasks: [],
            selectedListID: first.id,
            filterMode: .all
        )

        #expect(projection.selectedList?.id == first.id)
        #expect(projection.currentSort == .title)
    }

    @Test func sortSupportsAllModes() {
        let list = TaskList(name: "A")

        let early = Self.makeLinkedTask(
            title: "Bravo",
            list: list,
            createdAt: Self.date(2026, 3, 7, 9),
            dueDate: Self.date(2026, 3, 9, 0),
            sortOrder: 2
        )
        let late = Self.makeLinkedTask(
            title: "Alpha",
            list: list,
            createdAt: Self.date(2026, 3, 8, 9),
            dueDate: nil,
            sortOrder: 1
        )
        let dueSoon = Self.makeLinkedTask(
            title: "Charlie",
            list: list,
            createdAt: Self.date(2026, 3, 6, 9),
            dueDate: Self.date(2026, 3, 8, 0),
            sortOrder: 3
        )

        list.sort = .manual
        #expect(makeProjection(list: list, tasks: [early, late, dueSoon]).activeTasks.map(\.title) == ["Alpha", "Bravo", "Charlie"])

        list.sort = .date
        #expect(makeProjection(list: list, tasks: [early, late, dueSoon]).activeTasks.map(\.title) == ["Alpha", "Bravo", "Charlie"])

        list.sort = .dueDate
        #expect(makeProjection(list: list, tasks: [early, late, dueSoon]).activeTasks.map(\.title) == ["Charlie", "Bravo", "Alpha"])

        list.sort = .title
        #expect(makeProjection(list: list, tasks: [early, late, dueSoon]).activeTasks.map(\.title) == ["Alpha", "Bravo", "Charlie"])
    }

    @Test func dueDateGroupingKeepsSectionOrder() {
        let list = TaskList(name: "A")
        list.sort = .dueDate
        let tasks = [
            Self.makeLinkedTask(title: "noDue", list: list, createdAt: Self.date(2026, 3, 8, 9), dueDate: nil, sortOrder: 0),
            Self.makeLinkedTask(title: "tomorrow", list: list, createdAt: Self.date(2026, 3, 8, 8), dueDate: Self.date(2026, 3, 9, 8), sortOrder: 1),
            Self.makeLinkedTask(title: "today", list: list, createdAt: Self.date(2026, 3, 8, 7), dueDate: Self.date(2026, 3, 8, 10), sortOrder: 2),
            Self.makeLinkedTask(title: "overdue", list: list, createdAt: Self.date(2026, 3, 8, 6), dueDate: Self.date(2026, 3, 7, 10), sortOrder: 3),
            Self.makeLinkedTask(title: "upcoming", list: list, createdAt: Self.date(2026, 3, 8, 5), dueDate: Self.date(2026, 3, 12, 10), sortOrder: 4),
        ]

        let projection = makeProjection(list: list, tasks: tasks)

        #expect(projection.groupedActiveTasks.map(\.section) == [
            .overdue,
            .today,
            .tomorrow,
            .upcoming(Self.testCalendar.startOfDay(for: Self.date(2026, 3, 12, 10))),
            .noDueDate,
        ])
        #expect(projection.groupedActiveTasks.map { $0.tasks.map(\.title) } == [["overdue"], ["today"], ["tomorrow"], ["upcoming"], ["noDue"]])
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

    private static func makeLinkedTask(
        title: String,
        list: TaskList,
        createdAt: Date,
        dueDate: Date?,
        sortOrder: Int
    ) -> TaskItem {
        let task = makeDatedTask(title: title, createdAt: createdAt, dueDate: dueDate, sortOrder: sortOrder)
        task.list = list
        return task
    }

    private static func makeDatedTask(
        title: String,
        createdAt: Date,
        dueDate: Date?,
        sortOrder: Int
    ) -> TaskItem {
        let task = TaskItem(title: title, dueDate: dueDate, sortOrder: sortOrder)
        task.createdAt = createdAt
        return task
    }

    private func makeProjection(list: TaskList, tasks: [TaskItem]) -> ContentViewProjection {
        ContentViewProjection(
            lists: [list],
            allTasks: tasks,
            selectedListID: list.id,
            filterMode: .all,
            calendar: Self.testCalendar,
            now: Self.date(2026, 3, 8, 12)
        )
    }

    private static var testCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
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
