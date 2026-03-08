import SwiftUI

struct CompletedTasksSection: View {
    let tasks: [TaskItem]
    let onDeleteAll: () -> Void
    let actions: CompletedTaskActions
    @State private var isExpanded = false

    var body: some View {
        if !tasks.isEmpty {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(tasks) { task in
                    CompletedTaskRowView(
                        task: task,
                        onMarkIncomplete: {
                            actions.markIncomplete(task)
                        },
                        onDelete: {
                            actions.deleteCompletedTask(task)
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
