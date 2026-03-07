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
}
