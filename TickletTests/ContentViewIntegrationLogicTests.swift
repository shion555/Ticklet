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
        let viewModel = ContentViewCoordinator()

        let lists = try SwiftDataTestSupport.fetchLists(in: context)
        viewModel.bootstrap(using: listService, existingLists: lists)
        let fetchedLists = try SwiftDataTestSupport.fetchLists(in: context)
        let defaultList = fetchedLists.first(where: \.isDefault)

        #expect(defaultList != nil)
        #expect(fetchedLists.count == 1)
        #expect(fetchedLists.first?.isDefault == true)
        #expect(viewModel.selectedListID == defaultList?.id)
    }

    @Test func listDeletionFallbackUpdatesSelectionOnlyWhenNeeded() {
        let defaultList = TaskList(name: "Default", isDefault: true)
        let otherList = TaskList(name: "Other")
        let selectedList = TaskList(name: "Selected")
        let viewModel = ContentViewCoordinator()
        let listService = ListMutationService(modelContext: ModelContext(try! SwiftDataTestSupport.makeContainer()))

        viewModel.selectedListID = selectedList.id
        viewModel.listToDelete = selectedList
        viewModel.isPresentingDeleteConfirm = true
        viewModel.confirmDeleteList(using: listService, existingLists: [selectedList, otherList, defaultList])
        #expect(viewModel.selectedListID == defaultList.id)

        viewModel.selectedListID = otherList.id
        viewModel.listToDelete = selectedList
        viewModel.confirmDeleteList(using: listService, existingLists: [selectedList, otherList])
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
