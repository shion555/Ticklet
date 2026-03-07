import Foundation
import SwiftData
@testable import Ticklet

enum SwiftDataTestSupport {
    @MainActor
    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            TaskList.self,
            TaskItem.self,
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @MainActor
    static func fetchTasks(in context: ModelContext) throws -> [TaskItem] {
        try context.fetch(FetchDescriptor<TaskItem>())
    }

    @MainActor
    static func fetchLists(in context: ModelContext) throws -> [TaskList] {
        try context.fetch(FetchDescriptor<TaskList>())
    }
}
