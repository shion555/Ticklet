import SwiftUI
import SwiftData

struct SubtaskRowView: View {
    @Bindable var subtask: TaskItem
    @Environment(\.modelContext) private var modelContext

    private var taskMutationService: TaskMutationService {
        TaskMutationService(modelContext: modelContext)
    }

    var body: some View {
        HStack(spacing: 6) {
            Button {
                withAnimation {
                    taskMutationService.toggleSubtaskCompletion(subtask)
                }
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
                withAnimation {
                    taskMutationService.deleteTask(subtask)
                }
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}
