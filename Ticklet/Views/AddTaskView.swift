import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.modelContext) private var modelContext
    let list: TaskList?
    let nextSortOrder: Int

    @State private var title = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus")
                .foregroundStyle(.blue)
                .font(.callout)

            TextField("タスクを追加", text: $title)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit {
                    addTask()
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func addTask() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        withAnimation {
            let task = TaskItem(title: trimmed, sortOrder: nextSortOrder, list: list)
            modelContext.insert(task)
            title = ""
        }
    }
}
