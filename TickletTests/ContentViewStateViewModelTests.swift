import Foundation
import Testing
@testable import Ticklet

@MainActor
struct ContentViewStateViewModelTests {
    @Test func managesCreateRenameAndDeletePresentationState() {
        let viewModel = ContentViewStateViewModel()
        let list = TaskList(name: "Work")

        viewModel.presentCreateList()
        #expect(viewModel.showCreateList == true)
        viewModel.dismissCreateList()
        #expect(viewModel.showCreateList == false)

        viewModel.presentRenameList(list)
        #expect(viewModel.showRenameList == true)
        #expect(viewModel.listToRename?.id == list.id)
        viewModel.dismissRenameList()
        #expect(viewModel.showRenameList == false)
        #expect(viewModel.listToRename == nil)

        viewModel.presentDeleteList(list)
        #expect(viewModel.showDeleteConfirm == true)
        #expect(viewModel.listToDelete?.id == list.id)
        viewModel.dismissDeleteConfirm()
        #expect(viewModel.showDeleteConfirm == false)
        #expect(viewModel.listToDelete == nil)
    }

    @Test func togglesExpandedTaskAndCanCollapse() {
        let viewModel = ContentViewStateViewModel()
        let taskID = UUID()

        viewModel.toggleExpandedTask(taskID)
        #expect(viewModel.expandedTaskID == taskID)

        viewModel.toggleExpandedTask(taskID)
        #expect(viewModel.expandedTaskID == nil)

        viewModel.toggleExpandedTask(taskID)
        viewModel.collapseExpandedTask()
        #expect(viewModel.expandedTaskID == nil)
    }

    @Test func togglesFilterMode() {
        let viewModel = ContentViewStateViewModel()

        #expect(viewModel.filterMode == .all)
        viewModel.toggleFilterMode()
        #expect(viewModel.filterMode == .starred)
        viewModel.toggleFilterMode()
        #expect(viewModel.filterMode == .all)
    }

    @Test func syncInitialSelectionPrefersDefaultThenFirstAndKeepsExistingSelection() {
        let viewModel = ContentViewStateViewModel()
        let first = TaskList(name: "First")
        let second = TaskList(name: "Second")
        let defaultID = second.id

        viewModel.syncInitialSelection(with: [first, second], defaultListID: defaultID)
        #expect(viewModel.selectedListID == defaultID)

        let another = TaskList(name: "Another")
        let noDefaultViewModel = ContentViewStateViewModel()
        noDefaultViewModel.syncInitialSelection(with: [another, first], defaultListID: nil)
        #expect(noDefaultViewModel.selectedListID == another.id)

        let kept = ContentViewStateViewModel()
        kept.selectedListID = first.id
        kept.syncInitialSelection(with: [second], defaultListID: second.id)
        #expect(kept.selectedListID == first.id)
    }

    @Test func applyListDeletionFallbackOnlyAffectsDeletedSelection() {
        let viewModel = ContentViewStateViewModel()
        let selectedID = UUID()
        let fallbackID = UUID()

        viewModel.selectedListID = selectedID
        viewModel.applyListDeletionFallback(currentDeletedListID: UUID(), fallbackSelectedListID: fallbackID)
        #expect(viewModel.selectedListID == selectedID)

        viewModel.applyListDeletionFallback(currentDeletedListID: selectedID, fallbackSelectedListID: fallbackID)
        #expect(viewModel.selectedListID == fallbackID)
    }
}
