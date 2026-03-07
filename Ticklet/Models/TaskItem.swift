import Foundation
import SwiftData

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var details: String
    var createdAt: Date
    var completedAt: Date?
    var dueDate: Date?
    var isCompleted: Bool
    var isStarred: Bool
    var sortOrder: Int
    var recurrenceRuleRaw: String?

    var list: TaskList?

    var parentID: UUID?

    @Relationship(deleteRule: .cascade)
    var subtasks: [TaskItem] = []

    init(
        title: String,
        details: String = "",
        dueDate: Date? = nil,
        isStarred: Bool = false,
        sortOrder: Int = 0,
        list: TaskList? = nil,
        parentID: UUID? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.details = details
        self.createdAt = Date()
        self.completedAt = nil
        self.dueDate = dueDate
        self.isCompleted = false
        self.isStarred = isStarred
        self.sortOrder = sortOrder
        self.recurrenceRuleRaw = nil
        self.list = list
        self.parentID = parentID
    }

    var recurrenceRule: RecurrenceRule? {
        get {
            guard let raw = recurrenceRuleRaw else { return nil }
            return RecurrenceRule(rawValue: raw)
        }
        set { recurrenceRuleRaw = newValue?.rawValue }
    }

    var isTopLevel: Bool { parentID == nil }

    func markCompleted(at date: Date = Date()) {
        isCompleted = true
        completedAt = date
    }

    func markIncomplete() {
        isCompleted = false
        completedAt = nil
    }

    func toggleCompleted(at date: Date = Date()) {
        if isCompleted {
            markIncomplete()
        } else {
            markCompleted(at: date)
        }
    }

    func makeNextRecurringTask(
        calendar: Calendar = .current,
        referenceDate: Date = Date()
    ) -> TaskItem? {
        guard let rule = recurrenceRule else { return nil }

        let nextDate = RecurrenceHelper.nextDate(
            from: dueDate,
            rule: rule,
            calendar: calendar,
            referenceDate: referenceDate
        )
        let task = TaskItem(
            title: title,
            details: details,
            dueDate: nextDate,
            isStarred: isStarred,
            sortOrder: sortOrder,
            list: list
        )
        task.recurrenceRule = rule
        return task
    }

    func makeSubtask(title: String, sortOrder: Int) -> TaskItem {
        TaskItem(
            title: title,
            sortOrder: sortOrder,
            list: list,
            parentID: id
        )
    }

    func updateDueDate(_ dueDate: Date?) {
        self.dueDate = dueDate
    }

    func toggleStar() {
        isStarred.toggle()
    }
}
