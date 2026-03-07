import Foundation
import SwiftData
import Testing
@testable import Ticklet

@MainActor
struct TaskMutationServiceTests {
    @Test func addTaskPersistsProvidedAttributes() throws {
        let container = try SwiftDataTestSupport.makeContainer()
        let context = ModelContext(container)
        let service = TaskMutationService(modelContext: context)
        let list = TaskList(name: "Inbox")
        context.insert(list)

        let task = service.addTask(
            title: "Task",
            note: "note",
            dueDate: Self.date(2026, 3, 10, 8),
            recurrenceRule: .monthly,
            isStarred: true,
            sortOrder: 7,
            list: list
        )

        let tasks = try SwiftDataTestSupport.fetchTasks(in: context)
        #expect(tasks.count == 1)
        #expect(task.title == "Task")
        #expect(task.details == "note")
        #expect(task.dueDate == Self.date(2026, 3, 10, 8))
        #expect(task.recurrenceRule == .monthly)
        #expect(task.isStarred == true)
        #expect(task.sortOrder == 7)
        #expect(task.list?.id == list.id)
    }

    @Test func completeTaskCompletesNonRecurringTaskWithoutCreatingAnother() throws {
        let container = try SwiftDataTestSupport.makeContainer()
        let context = ModelContext(container)
        let service = TaskMutationService(modelContext: context)
        let task = TaskItem(title: "One-off")
        context.insert(task)

        service.completeTask(task, completionDate: Self.date(2026, 3, 8, 10), calendar: Self.testCalendar)

        let tasks = try SwiftDataTestSupport.fetchTasks(in: context)
        #expect(task.isCompleted == true)
        #expect(task.completedAt == Self.date(2026, 3, 8, 10))
        #expect(tasks.count == 1)
    }

    @Test func completeTaskCreatesNextRecurringTask() throws {
        let container = try SwiftDataTestSupport.makeContainer()
        let context = ModelContext(container)
        let service = TaskMutationService(modelContext: context)
        let list = TaskList(name: "Inbox")
        let task = TaskItem(
            title: "Repeat",
            details: "note",
            dueDate: Self.date(2026, 3, 8, 9),
            isStarred: true,
            sortOrder: 2,
            list: list
        )
        task.recurrenceRule = .daily
        context.insert(list)
        context.insert(task)

        service.completeTask(task, completionDate: Self.date(2026, 3, 8, 12), calendar: Self.testCalendar)

        let tasks = try SwiftDataTestSupport.fetchTasks(in: context)
        let nextTask = tasks.first(where: { $0.id != task.id })

        #expect(tasks.count == 2)
        #expect(task.isCompleted == true)
        #expect(nextTask?.title == "Repeat")
        #expect(nextTask?.details == "note")
        #expect(nextTask?.dueDate == Self.date(2026, 3, 9, 9))
        #expect(nextTask?.list?.id == list.id)
        #expect(nextTask?.recurrenceRule == .daily)
        #expect(nextTask?.isCompleted == false)
    }

    @Test func markTaskIncompleteResetsCompletionState() {
        let service = TaskMutationService(modelContext: ModelContext(try! SwiftDataTestSupport.makeContainer()))
        let task = TaskItem(title: "Task")
        task.markCompleted(at: Self.date(2026, 3, 8, 10))

        service.markTaskIncomplete(task)

        #expect(task.isCompleted == false)
        #expect(task.completedAt == nil)
    }

    @Test func addSubtaskUsesParentListAndSortOrder() throws {
        let container = try SwiftDataTestSupport.makeContainer()
        let context = ModelContext(container)
        let service = TaskMutationService(modelContext: context)
        let list = TaskList(name: "Inbox")
        let parent = TaskItem(title: "Parent", list: list)
        parent.subtasks.append(parent.makeSubtask(title: "Existing", sortOrder: 0))
        context.insert(list)
        context.insert(parent)

        let subtask = service.addSubtask(title: "Child", to: parent)

        #expect(subtask.parentID == parent.id)
        #expect(subtask.list?.id == list.id)
        #expect(subtask.sortOrder == 1)
        #expect(parent.subtasks.count == 2)
    }

    @Test func toggleSubtaskCompletionFlipsCompletionState() {
        let service = TaskMutationService(modelContext: ModelContext(try! SwiftDataTestSupport.makeContainer()))
        let subtask = TaskItem(title: "Subtask", parentID: UUID())

        service.toggleSubtaskCompletion(subtask)
        #expect(subtask.isCompleted == true)
        #expect(subtask.completedAt != nil)

        service.toggleSubtaskCompletion(subtask)
        #expect(subtask.isCompleted == false)
        #expect(subtask.completedAt == nil)
    }

    @Test func deleteCompletedTasksDeletesOnlyProvidedTasks() throws {
        let container = try SwiftDataTestSupport.makeContainer()
        let context = ModelContext(container)
        let service = TaskMutationService(modelContext: context)
        let first = TaskItem(title: "First")
        let second = TaskItem(title: "Second")
        context.insert(first)
        context.insert(second)

        service.deleteCompletedTasks([first])

        let tasks = try SwiftDataTestSupport.fetchTasks(in: context)
        #expect(tasks.map(\.title) == ["Second"])
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
