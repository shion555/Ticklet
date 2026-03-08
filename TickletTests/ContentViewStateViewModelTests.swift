import Foundation
import SwiftData
import Testing
@testable import Ticklet

@MainActor
struct ContentViewCoordinatorTests {
    @Test func managesCreateRenameAndDeletePresentationState() {
        let viewModel = ContentViewCoordinator()
        let list = TaskList(name: "Work")

        viewModel.presentCreateList()
        #expect(viewModel.isPresentingCreateList == true)
        viewModel.dismissCreateList()
        #expect(viewModel.isPresentingCreateList == false)

        viewModel.presentRenameList(list)
        #expect(viewModel.isPresentingRenameList == true)
        #expect(viewModel.listToRename?.id == list.id)
        viewModel.dismissRenameList()
        #expect(viewModel.isPresentingRenameList == false)
        #expect(viewModel.listToRename == nil)

        viewModel.presentDeleteList(list)
        #expect(viewModel.isPresentingDeleteConfirm == true)
        #expect(viewModel.listToDelete?.id == list.id)
        viewModel.dismissDeleteConfirm()
        #expect(viewModel.isPresentingDeleteConfirm == false)
        #expect(viewModel.listToDelete == nil)
    }

    @Test func togglesExpandedTaskAndCanCollapse() {
        let viewModel = ContentViewCoordinator()
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
        let viewModel = ContentViewCoordinator()

        #expect(viewModel.filterMode == .all)
        viewModel.toggleFilterMode()
        #expect(viewModel.filterMode == .starred)
        viewModel.toggleFilterMode()
        #expect(viewModel.filterMode == .all)
    }

    @Test func bootstrapPrefersDefaultThenFirstAndKeepsExistingSelection() {
        let container = try! SwiftDataTestSupport.makeContainer()
        let context = ModelContext(container)
        let listService = ListMutationService(modelContext: context)
        let viewModel = ContentViewCoordinator()
        let first = TaskList(name: "First")
        let second = TaskList(name: "Second")
        first.sortOrder = 0
        second.sortOrder = 1
        context.insert(first)
        context.insert(second)
        let defaultID = second.id
        second.isDefault = true

        viewModel.bootstrap(using: listService, existingLists: [first, second])
        #expect(viewModel.selectedListID == defaultID)

        let another = TaskList(name: "Another")
        let noDefaultViewModel = ContentViewCoordinator()
        noDefaultViewModel.bootstrap(using: listService, existingLists: [another, first])
        #expect(noDefaultViewModel.selectedListID == another.id)

        let kept = ContentViewCoordinator()
        kept.selectedListID = first.id
        kept.bootstrap(using: listService, existingLists: [second])
        #expect(kept.selectedListID == first.id)
    }

    @Test func confirmDeleteListAppliesFallbackOnlyForDeletedSelection() {
        let listService = ListMutationService(modelContext: ModelContext(try! SwiftDataTestSupport.makeContainer()))
        let viewModel = ContentViewCoordinator()
        let selectedID = UUID()
        let fallbackID = UUID()
        let deleted = TaskList(name: "Deleted")
        deleted.id = selectedID
        let fallback = TaskList(name: "Fallback", isDefault: true)
        fallback.id = fallbackID

        viewModel.selectedListID = selectedID
        viewModel.listToDelete = TaskList(name: "Other")
        viewModel.confirmDeleteList(using: listService, existingLists: [fallback])
        #expect(viewModel.selectedListID == selectedID)

        viewModel.listToDelete = deleted
        viewModel.isPresentingDeleteConfirm = true
        viewModel.confirmDeleteList(using: listService, existingLists: [deleted, fallback])
        #expect(viewModel.selectedListID == fallbackID)
        #expect(viewModel.isPresentingDeleteConfirm == false)
        #expect(viewModel.listToDelete == nil)
    }

    @Test func handleEscapeKeyPressCollapsesExpandedTaskWhenPresent() {
        let viewModel = ContentViewCoordinator()
        let taskID = UUID()

        #expect(viewModel.handleEscapeKeyPress() == false)

        viewModel.expandedTaskID = taskID
        #expect(viewModel.handleEscapeKeyPress() == true)
        #expect(viewModel.expandedTaskID == nil)
    }
}
