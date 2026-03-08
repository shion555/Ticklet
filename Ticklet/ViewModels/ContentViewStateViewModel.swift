import Foundation
import Observation

@MainActor
@Observable
final class ContentViewCoordinator {
    var selectedListID: UUID?
    var filterMode: FilterMode = .all
    var expandedTaskID: UUID?

    var isPresentingCreateList = false
    var isPresentingRenameList = false
    var listToRename: TaskList?
    var isPresentingDeleteConfirm = false
    var listToDelete: TaskList?

    func toggleExpandedTask(_ taskID: UUID) {
        expandedTaskID = expandedTaskID == taskID ? nil : taskID
    }

    func collapseExpandedTask() {
        expandedTaskID = nil
    }

    func handleEscapeKeyPress() -> Bool {
        guard expandedTaskID != nil else { return false }
        collapseExpandedTask()
        return true
    }

    func presentCreateList() {
        isPresentingCreateList = true
    }

    func presentRenameList(_ list: TaskList) {
        listToRename = list
        isPresentingRenameList = true
    }

    func presentDeleteList(_ list: TaskList) {
        listToDelete = list
        isPresentingDeleteConfirm = true
    }

    func dismissCreateList() {
        isPresentingCreateList = false
    }

    func dismissRenameList() {
        isPresentingRenameList = false
        listToRename = nil
    }

    func dismissDeleteConfirm() {
        isPresentingDeleteConfirm = false
        listToDelete = nil
    }

    func selectList(_ listID: UUID?) {
        selectedListID = listID
    }

    func toggleFilterMode() {
        filterMode = filterMode == .all ? .starred : .all
    }

    func bootstrap(using listMutationService: ListMutationService, existingLists: [TaskList]) {
        let defaultList = listMutationService.initializeDefaultList(existingLists: existingLists)
        let defaultListID = defaultList?.id ?? existingLists.first(where: \.isDefault)?.id
        syncInitialSelection(with: existingLists, defaultListID: defaultListID)
    }

    func confirmDeleteList(using listMutationService: ListMutationService, existingLists: [TaskList]) {
        guard let list = listToDelete else { return }
        listMutationService.deleteList(list)
        let fallbackSelectedListID = listMutationService.fallbackSelectedListID(
            afterDeleting: list,
            remainingLists: existingLists
        )
        applyListDeletionFallback(
            currentDeletedListID: list.id,
            fallbackSelectedListID: fallbackSelectedListID
        )
        dismissDeleteConfirm()
    }

    private func syncInitialSelection(with lists: [TaskList], defaultListID: UUID?) {
        guard selectedListID == nil else { return }
        selectedListID = defaultListID ?? lists.first?.id
    }

    private func applyListDeletionFallback(currentDeletedListID: UUID, fallbackSelectedListID: UUID?) {
        guard selectedListID == currentDeletedListID else { return }
        selectedListID = fallbackSelectedListID
    }
}
