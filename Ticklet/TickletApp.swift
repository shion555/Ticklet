import SwiftUI
import SwiftData

@main
struct TickletApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaskList.self,
            TaskItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        MenuBarExtra("Ticklet", systemImage: "checkmark.circle") {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.window)
    }
}
