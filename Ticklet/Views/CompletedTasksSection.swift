import SwiftUI
import SwiftData

struct CompletedTasksSection: View {
    @Environment(\.modelContext) private var modelContext
    let tasks: [TaskItem]
    let onDeleteAll: () -> Void
    @State private var isExpanded = false

    private var taskMutationService: TaskMutationService {
        TaskMutationService(modelContext: modelContext)
    }

    var body: some View {
        if !tasks.isEmpty {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(tasks) { task in
                    CompletedTaskRowView(
                        task: task,
                        onMarkIncomplete: {
                            withAnimation {
                                taskMutationService.markTaskIncomplete(task)
                            }
                        },
                        onDelete: {
                            withAnimation {
                                taskMutationService.deleteTask(task)
                            }
                        }
                    )
                }
            } label: {
                Text("完了済み (\(tasks.count))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .accessibilityIdentifier("completed-section")
        }
    }
}
