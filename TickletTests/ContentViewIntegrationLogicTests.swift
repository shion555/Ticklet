import Foundation
import SwiftData
import Testing
@testable import Ticklet

@MainActor
struct ContentViewIntegrationLogicTests {
    @Test func defaultListInitializationAndSelectionStayInSync() throws {
        let container = try SwiftDataTestSupport.makeContainer()
        let context = ModelContext(container)
        let listService = ListMutationService(modelContext: context)
        let viewModel = ContentViewStateViewModel()

        let defaultList = listService.initializeDefaultList(existingLists: [])
        let lists = try SwiftDataTestSupport.fetchLists(in: context)

        viewModel.syncInitialSelection(with: lists, defaultListID: defaultList?.id)

        #expect(defaultList != nil)
        #expect(lists.count == 1)
        #expect(lists.first?.isDefault == true)
        #expect(viewModel.selectedListID == defaultList?.id)
    }

    @Test func listDeletionFallbackUpdatesSelectionOnlyWhenNeeded() {
        let defaultList = TaskList(name: "Default", isDefault: true)
        let otherList = TaskList(name: "Other")
        let selectedList = TaskList(name: "Selected")
        let viewModel = ContentViewStateViewModel()
        let listService = ListMutationService(modelContext: ModelContext(try! SwiftDataTestSupport.makeContainer()))

        viewModel.selectedListID = selectedList.id
        let fallbackID = listService.fallbackSelectedListID(
            afterDeleting: selectedList,
            remainingLists: [selectedList, otherList, defaultList]
        )
        viewModel.applyListDeletionFallback(
            currentDeletedListID: selectedList.id,
            fallbackSelectedListID: fallbackID
        )
        #expect(viewModel.selectedListID == defaultList.id)

        viewModel.selectedListID = otherList.id
        viewModel.applyListDeletionFallback(
            currentDeletedListID: selectedList.id,
            fallbackSelectedListID: nil
        )
        #expect(viewModel.selectedListID == otherList.id)
    }

    @Test func readModelKeepsSelectedListSortAndTaskBucketsAligned() {
        let work = TaskList(name: "Work")
        work.sort = .title
        let personal = TaskList(name: "Personal")

        let activeWork = TaskItem(title: "Bravo", sortOrder: 1, list: work)
        let completedWork = TaskItem(title: "Done", sortOrder: 2, list: work)
        completedWork.isCompleted = true
        let activePersonal = TaskItem(title: "Alpha", sortOrder: 0, list: personal)

        let readModel = ContentViewReadModel(
            lists: [personal, work],
            allTasks: [activeWork, completedWork, activePersonal],
            selectedListID: work.id,
            filterMode: .all
        )

        #expect(readModel.selectedList?.id == work.id)
        #expect(readModel.currentSort == .title)
        #expect(readModel.activeTasks.map(\.title) == ["Bravo"])
        #expect(readModel.completedTasks.map(\.title) == ["Done"])
    }
}
