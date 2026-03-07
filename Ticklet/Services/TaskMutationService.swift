import Foundation
import SwiftData

struct TaskMutationService {
    let modelContext: ModelContext

    @discardableResult
    func addTask(
        title: String,
        note: String,
        dueDate: Date?,
        recurrenceRule: RecurrenceRule?,
        isStarred: Bool,
        sortOrder: Int,
        list: TaskList?
    ) -> TaskItem {
        let task = TaskItem(
            title: title,
            details: note,
            dueDate: dueDate,
            isStarred: isStarred,
            sortOrder: sortOrder,
            list: list
        )
        task.recurrenceRule = recurrenceRule
        modelContext.insert(task)
        return task
    }

    func completeTask(
        _ task: TaskItem,
        completionDate: Date = Date(),
        calendar: Calendar = .current
    ) {
        task.toggleCompleted(at: completionDate)

        guard task.isCompleted, let nextTask = task.makeNextRecurringTask(calendar: calendar, referenceDate: completionDate) else {
            return
        }

        modelContext.insert(nextTask)
    }

    func markTaskIncomplete(_ task: TaskItem) {
        task.markIncomplete()
    }

    func toggleStar(for task: TaskItem) {
        task.toggleStar()
    }

    func updateDueDate(for task: TaskItem, to dueDate: Date?) {
        task.updateDueDate(dueDate)
    }

    @discardableResult
    func addSubtask(title: String, to parent: TaskItem) -> TaskItem {
        let subtask = parent.makeSubtask(title: title, sortOrder: parent.subtasks.count)
        parent.subtasks.append(subtask)
        modelContext.insert(subtask)
        return subtask
    }

    func toggleSubtaskCompletion(_ subtask: TaskItem) {
        subtask.toggleCompleted()
    }

    func deleteTask(_ task: TaskItem) {
        modelContext.delete(task)
    }

    func deleteCompletedTasks(_ tasks: [TaskItem]) {
        for task in tasks {
            modelContext.delete(task)
        }
    }
}
