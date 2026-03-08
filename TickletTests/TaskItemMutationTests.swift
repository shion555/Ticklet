import Foundation
import Testing
@testable import Ticklet

@MainActor
struct TaskItemMutationTests {
    @Test func markCompletedAndIncompleteUpdateCompletionState() {
        let task = TaskItem(title: "Task")
        let completedAt = Self.date(2026, 3, 8, 9)

        task.markCompleted(at: completedAt)
        #expect(task.isCompleted == true)
        #expect(task.completedAt == completedAt)

        task.markIncomplete()
        #expect(task.isCompleted == false)
        #expect(task.completedAt == nil)
    }

    @Test func toggleStarAndUpdateDueDateMutateTask() {
        let task = TaskItem(title: "Task")
        let dueDate = Self.date(2026, 3, 10, 8)

        task.toggleStar()
        task.updateDueDate(dueDate)

        #expect(task.isStarred == true)
        #expect(task.dueDate == dueDate)
    }

    @Test func makeSubtaskInheritsParentIdentityAndList() {
        let list = TaskList(name: "Inbox")
        let parent = TaskItem(title: "Parent", list: list)

        let subtask = parent.makeSubtask(title: "Child", sortOrder: 3)

        #expect(subtask.parentID == parent.id)
        #expect(subtask.list?.id == list.id)
        #expect(subtask.sortOrder == 3)
        #expect(subtask.title == "Child")
    }

    @Test func makeSubtaskStartsWithIndependentDefaultState() {
        let list = TaskList(name: "Inbox")
        let parent = TaskItem(
            title: "Parent",
            details: "note",
            dueDate: Self.date(2026, 3, 10, 8),
            isStarred: true,
            sortOrder: 2,
            list: list
        )
        parent.recurrenceRule = .daily
        parent.markCompleted(at: Self.date(2026, 3, 8, 9))

        let subtask = parent.makeSubtask(title: "Child", sortOrder: 0)

        #expect(subtask.details.isEmpty)
        #expect(subtask.dueDate == nil)
        #expect(subtask.recurrenceRule == nil)
        #expect(subtask.isStarred == false)
        #expect(subtask.isCompleted == false)
        #expect(subtask.completedAt == nil)
    }

    @Test func toggleCompletedOnSubtaskUpdatesCompletionState() {
        let subtask = TaskItem(title: "Child", parentID: UUID())
        let completedAt = Self.date(2026, 3, 8, 11)

        subtask.toggleCompleted(at: completedAt)
        #expect(subtask.isCompleted == true)
        #expect(subtask.completedAt == completedAt)

        subtask.toggleCompleted(at: Self.date(2026, 3, 8, 12))
        #expect(subtask.isCompleted == false)
        #expect(subtask.completedAt == nil)
    }

    @Test func makeNextRecurringTaskKeepsTaskAttributesButResetsCompletion() {
        let list = TaskList(name: "Inbox")
        let task = TaskItem(
            title: "Repeat",
            details: "note",
            dueDate: Self.date(2026, 3, 8, 9),
            isStarred: true,
            sortOrder: 5,
            list: list
        )
        task.recurrenceRule = .weekly
        task.markCompleted(at: Self.date(2026, 3, 8, 10))

        let nextTask = task.makeNextRecurringTask(
            calendar: Self.testCalendar,
            referenceDate: Self.date(2026, 3, 8, 10)
        )

        #expect(nextTask != nil)
        #expect(nextTask?.title == "Repeat")
        #expect(nextTask?.details == "note")
        #expect(nextTask?.dueDate == Self.date(2026, 3, 15, 9))
        #expect(nextTask?.isStarred == true)
        #expect(nextTask?.sortOrder == 5)
        #expect(nextTask?.list?.id == list.id)
        #expect(nextTask?.isCompleted == false)
        #expect(nextTask?.completedAt == nil)
        #expect(nextTask?.parentID == nil)
        #expect(nextTask?.recurrenceRule == .weekly)
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
