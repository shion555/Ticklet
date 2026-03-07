import Foundation
import SwiftData
import Testing
@testable import Ticklet

@MainActor
struct ListMutationServiceTests {
    @Test func initializeDefaultListReusesExistingDefault() throws {
        let container = try SwiftDataTestSupport.makeContainer()
        let context = ModelContext(container)
        let service = ListMutationService(modelContext: context)
        let existing = TaskList(name: "マイタスク", isDefault: true)
        context.insert(existing)

        let result = service.initializeDefaultList(existingLists: [existing])
        let lists = try SwiftDataTestSupport.fetchLists(in: context)

        #expect(result?.id == existing.id)
        #expect(lists.count == 1)
    }

    @Test func initializeDefaultListCreatesOneWhenMissing() throws {
        let container = try SwiftDataTestSupport.makeContainer()
        let context = ModelContext(container)
        let service = ListMutationService(modelContext: context)

        let result = service.initializeDefaultList(existingLists: [])
        let lists = try SwiftDataTestSupport.fetchLists(in: context)

        #expect(result != nil)
        #expect(result?.isDefault == true)
        #expect(result?.name == "マイタスク")
        #expect(lists.count == 1)
    }

    @Test func createListUsesProvidedSortOrder() throws {
        let container = try SwiftDataTestSupport.makeContainer()
        let context = ModelContext(container)
        let service = ListMutationService(modelContext: context)

        let list = service.createList(name: " Work ", sortOrder: 4)

        #expect(list.name == "Work")
        #expect(list.sortOrder == 4)
        #expect(try SwiftDataTestSupport.fetchLists(in: context).count == 1)
    }

    @Test func renameListTrimsWhitespace() {
        let service = ListMutationService(modelContext: ModelContext(try! SwiftDataTestSupport.makeContainer()))
        let list = TaskList(name: "Before")

        service.renameList(list, to: " After ")

        #expect(list.name == "After")
    }

    @Test func fallbackSelectedListIDReturnsAnotherDefaultOrNil() {
        let service = ListMutationService(modelContext: ModelContext(try! SwiftDataTestSupport.makeContainer()))
        let deleted = TaskList(name: "Deleted", isDefault: true)
        let fallback = TaskList(name: "Default", isDefault: true)
        let normal = TaskList(name: "Other")

        #expect(
            service.fallbackSelectedListID(afterDeleting: deleted, remainingLists: [deleted, normal, fallback]) == fallback.id
        )
        #expect(
            service.fallbackSelectedListID(afterDeleting: deleted, remainingLists: [deleted, normal]) == nil
        )
    }
}
