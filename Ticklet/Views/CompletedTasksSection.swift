import SwiftUI
import SwiftData

struct CompletedTasksSection: View {
    let tasks: [TaskItem]
    let onDeleteAll: () -> Void
    @State private var isExpanded = false

    var body: some View {
        if !tasks.isEmpty {
            DisclosureGroup(isExpanded: $isExpanded) {
                ForEach(tasks) { task in
                    CompletedRow(task: task)
                }
            } label: {
                Text("完了済み (\(tasks.count))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct CompletedRow: View {
    @Bindable var task: TaskItem
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 6) {
            Button {
                withAnimation {
                    task.isCompleted = false
                    task.completedAt = nil
                }
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            Text(task.title)
                .strikethrough()
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(role: .destructive) {
                withAnimation { modelContext.delete(task) }
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}
