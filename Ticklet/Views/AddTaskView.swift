import SwiftUI

struct AddTaskView: View {
    let list: TaskList?
    let nextSortOrder: Int
    let actions: AddTaskActions

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
                .accessibilityIdentifier("add-task-field")
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

        actions.addQuickTask(trimmed, list, nextSortOrder)
        title = ""
    }
}
