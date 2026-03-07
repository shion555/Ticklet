import Foundation
import SwiftData

@Model
final class TaskList {
    var id: UUID
    var name: String
    var createdAt: Date
    var sortOrder: Int
    var isDefault: Bool
    var sortOption: String

    @Relationship(deleteRule: .cascade, inverse: \TaskItem.list)
    var tasks: [TaskItem] = []

    init(name: String, sortOrder: Int = 0, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.sortOption = SortOption.manual.rawValue
    }

    var sort: SortOption {
        get { SortOption(rawValue: sortOption) ?? .manual }
        set { sortOption = newValue.rawValue }
    }
}
