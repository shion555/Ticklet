import SwiftUI

struct SubtaskRowView: View {
    @Bindable var subtask: TaskItem
    let actions: SubtaskActions

    var body: some View {
        HStack(spacing: 6) {
            Button {
                actions.toggleSubtaskCompletion(subtask)
            } label: {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(subtask.isCompleted ? .gray : .blue)
                    .font(.caption)
            }
            .buttonStyle(.plain)

            TextField("サブタスク", text: $subtask.title)
                .textFieldStyle(.plain)
                .font(.callout)
                .strikethrough(subtask.isCompleted)
                .foregroundStyle(subtask.isCompleted ? .secondary : .primary)
        }
        .padding(.leading, 24)
        .contextMenu {
            Button(role: .destructive) {
                actions.deleteSubtask(subtask)
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}
