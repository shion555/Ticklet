import SwiftUI

struct SubtaskRowView: View {
    @Bindable var subtask: TaskItem
    let actions: SubtaskActions

    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--ui-testing")
    }

    var body: some View {
        HStack(spacing: 6) {
            Button {
                actions.toggleSubtaskCompletion(subtask)
            } label: {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(subtask.isCompleted ? .gray : .blue)
                    .font(.caption)
            }
            .accessibilityIdentifier("subtask-complete-\(subtask.id.uuidString)")
            .buttonStyle(.plain)

            TextField("サブタスク", text: $subtask.title)
                .textFieldStyle(.plain)
                .font(.callout)
                .strikethrough(subtask.isCompleted)
                .foregroundStyle(subtask.isCompleted ? .secondary : .primary)
                .accessibilityIdentifier("subtask-title-\(subtask.id.uuidString)")
        }
        .padding(.leading, 24)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("subtask-row-\(subtask.id.uuidString)")
        .overlay(alignment: .trailing) {
            if isUITesting {
                Button {
                    actions.deleteSubtask(subtask)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("サブタスク削除")
                .accessibilityIdentifier("subtask-delete-\(subtask.id.uuidString)")
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                actions.deleteSubtask(subtask)
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}
