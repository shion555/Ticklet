import Foundation
import Testing
@testable import Ticklet

struct ContentViewReadModelTests {
    @Test func fallsBackWhenNoListIsSelected() {
        let readModel = ContentViewReadModel(
            lists: [],
            allTasks: [],
            selectedListID: nil,
            filterMode: .all
        )

        #expect(readModel.selectedList == nil)
        #expect(readModel.selectedListID == nil)
        #expect(readModel.selectedListName == "マイタスク")
        #expect(readModel.currentSort == .manual)
        #expect(readModel.renameableSelectedList == nil)
    }

    @Test func reflectsSelectedListMetadata() {
        let list = TaskList(name: "Work", sortOrder: 2)
        list.sort = .title

        let readModel = ContentViewReadModel(
            lists: [list],
            allTasks: [],
            selectedListID: list.id,
            filterMode: .all
        )

        #expect(readModel.selectedList?.id == list.id)
        #expect(readModel.selectedListName == "Work")
        #expect(readModel.currentSort == .title)
        #expect(readModel.renameableSelectedList?.id == list.id)
    }

    @Test func allFilterOnlyUsesSelectedListTopLevelIncompleteTasks() {
        let listA = TaskList(name: "A")
        let listB = TaskList(name: "B")
        let match = makeTask(title: "match", list: listA, sortOrder: 4)
        let completed = makeTask(title: "completed", list: listA, isCompleted: true)
        let subtask = makeTask(title: "subtask", list: listA, parentID: UUID())
        let otherList = makeTask(title: "other", list: listB)

        let readModel = ContentViewReadModel(
            lists: [listA, listB],
            allTasks: [match, completed, subtask, otherList],
            selectedListID: listA.id,
            filterMode: .all
        )

        #expect(readModel.activeTasks.map(\.title) == ["match"])
        #expect(readModel.completedTasks.map(\.title) == ["completed"])
        #expect(readModel.nextSortOrder == 5)
    }

    @Test func starredFilterCrossesListsForActiveAndCompletedTasks() {
        let listA = TaskList(name: "A")
        let listB = TaskList(name: "B")
        let activeStarA = makeTask(title: "activeA", list: listA, isStarred: true)
        let activeStarB = makeTask(title: "activeB", list: listB, isStarred: true)
        let completedStar = makeTask(title: "done", list: listB, isCompleted: true, isStarred: true)
        let plain = makeTask(title: "plain", list: listA)

        let readModel = ContentViewReadModel(
            lists: [listA, listB],
            allTasks: [activeStarB, plain, completedStar, activeStarA],
            selectedListID: listA.id,
            filterMode: .starred
        )

        #expect(Set(readModel.activeTasks.map(\.title)) == Set(["activeA", "activeB"]))
        #expect(readModel.completedTasks.map(\.title) == ["done"])
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

        let readModel = ContentViewReadModel(
            lists: [list],
            allTasks: [task],
            selectedListID: list.id,
            filterMode: .all
        )

        #expect(readModel.showsGroupedActiveTasks == true)
        #expect(readModel.groupedActiveTasks.map(\.tasks).flatMap { $0 }.map(\.title) == ["upcoming"])
    }

    @Test func groupedActiveTasksMatchQueryServiceOrder() {
        let list = TaskList(name: "A")
        list.sort = .date
        let tasks = [
            makeTask(title: "none", list: list),
            Self.makeLinkedTask(title: "today", list: list, createdAt: Self.date(2026, 3, 8, 8), dueDate: Self.date(2026, 3, 8, 10), sortOrder: 0),
            Self.makeLinkedTask(title: "later", list: list, createdAt: Self.date(2026, 3, 8, 9), dueDate: Self.date(2026, 3, 12, 10), sortOrder: 1),
        ]

        let readModel = ContentViewReadModel(
            lists: [list],
            allTasks: tasks,
            selectedListID: list.id,
            filterMode: .all
        )

        let expected = TaskQueryService.groupedByDate(readModel.activeTasks)
        #expect(readModel.groupedActiveTasks.map(\.section) == expected.map(\.section))
    }

    @Test func defaultListCannotBeRenamed() {
        let list = TaskList(name: "Default", isDefault: true)

        let readModel = ContentViewReadModel(
            lists: [list],
            allTasks: [],
            selectedListID: list.id,
            filterMode: .all
        )

        #expect(readModel.renameableSelectedList == nil)
    }

    @Test func listsAreSortedBySortOrder() {
        let first = TaskList(name: "First", sortOrder: 2)
        let second = TaskList(name: "Second", sortOrder: 0)
        let third = TaskList(name: "Third", sortOrder: 1)

        let readModel = ContentViewReadModel(
            lists: [first, second, third],
            allTasks: [],
            selectedListID: nil,
            filterMode: .all
        )

        #expect(readModel.sortedLists.map(\.name) == ["Second", "Third", "First"])
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
