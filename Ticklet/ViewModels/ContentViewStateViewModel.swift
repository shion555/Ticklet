import Foundation
import Observation

@MainActor
@Observable
final class ContentViewStateViewModel {
    var selectedListID: UUID?
    var filterMode: FilterMode = .all
    var expandedTaskID: UUID?

    var showCreateList = false
    var showRenameList = false
    var listToRename: TaskList?
    var showDeleteConfirm = false
    var listToDelete: TaskList?

    func toggleExpandedTask(_ taskID: UUID) {
        expandedTaskID = expandedTaskID == taskID ? nil : taskID
    }

    func collapseExpandedTask() {
        expandedTaskID = nil
    }

    func presentCreateList() {
        showCreateList = true
    }

    func presentRenameList(_ list: TaskList) {
        listToRename = list
        showRenameList = true
    }

    func presentDeleteList(_ list: TaskList) {
        listToDelete = list
        showDeleteConfirm = true
    }

    func dismissCreateList() {
        showCreateList = false
    }

    func dismissRenameList() {
        showRenameList = false
        listToRename = nil
    }

    func dismissDeleteConfirm() {
        showDeleteConfirm = false
        listToDelete = nil
    }

    func selectList(_ listID: UUID?) {
        selectedListID = listID
    }

    func toggleFilterMode() {
        filterMode = filterMode == .all ? .starred : .all
    }

    func syncInitialSelection(with lists: [TaskList], defaultListID: UUID?) {
        guard selectedListID == nil else { return }
        selectedListID = defaultListID ?? lists.first?.id
    }

    func applyListDeletionFallback(currentDeletedListID: UUID, fallbackSelectedListID: UUID?) {
        guard selectedListID == currentDeletedListID else { return }
        selectedListID = fallbackSelectedListID
    }
}
