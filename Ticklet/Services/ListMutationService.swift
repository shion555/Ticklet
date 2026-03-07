import Foundation
import SwiftData

struct ListMutationService {
    let modelContext: ModelContext

    @discardableResult
    func initializeDefaultList(existingLists: [TaskList]) -> TaskList? {
        if let defaultList = existingLists.first(where: \.isDefault) {
            return defaultList
        }

        guard existingLists.isEmpty else { return nil }

        let defaultList = TaskList(name: "マイタスク", sortOrder: 0, isDefault: true)
        modelContext.insert(defaultList)
        return defaultList
    }

    @discardableResult
    func createList(name: String, sortOrder: Int) -> TaskList {
        let list = TaskList(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            sortOrder: sortOrder
        )
        modelContext.insert(list)
        return list
    }

    func renameList(_ list: TaskList, to name: String) {
        list.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func deleteList(_ list: TaskList) {
        modelContext.delete(list)
    }

    func fallbackSelectedListID(afterDeleting list: TaskList, remainingLists: [TaskList]) -> UUID? {
        remainingLists.first { $0.id != list.id && $0.isDefault }?.id
    }
}
