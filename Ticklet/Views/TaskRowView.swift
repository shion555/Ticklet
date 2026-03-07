import SwiftUI
import SwiftData

struct TaskRowView: View {
    @Bindable var task: TaskItem
    @Environment(\.modelContext) private var modelContext
    let isExpanded: Bool
    let onTap: () -> Void
    let onComplete: () -> Void

    @State private var isHovering = false
    @FocusState private var titleFocused: Bool
    @FocusState private var detailsFocused: Bool
    @State private var showDatePicker = false
    @State private var pickerDate = Date()

    private var taskMutationService: TaskMutationService {
        TaskMutationService(modelContext: modelContext)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TaskRowHeaderView(
                title: $task.title,
                dueDate: task.dueDate,
                isExpanded: isExpanded,
                isCompleted: task.isCompleted,
                isStarred: task.isStarred,
                isHovering: isHovering,
                titleFocused: $titleFocused,
                onTap: onTap,
                onComplete: onComplete,
                onToggleStar: {
                    withAnimation { taskMutationService.toggleStar(for: task) }
                },
                onUpdateDueDate: { newDate in
                    taskMutationService.updateDueDate(for: task, to: newDate)
                }
            )

            if isExpanded {
                TaskRowDetailsView(
                    details: $task.details,
                    recurrenceRule: Binding(
                        get: { task.recurrenceRule },
                        set: { task.recurrenceRule = $0 }
                    ),
                    dueDate: task.dueDate,
                    detailsFocused: $detailsFocused,
                    showDatePicker: $showDatePicker,
                    pickerDate: $pickerDate,
                    onSelectToday: { selectToday() },
                    onSelectTomorrow: { selectTomorrow() },
                    onUpdateDueDate: { newDate in
                        taskMutationService.updateDueDate(for: task, to: newDate)
                    }
                )
            }

            let subtasks = (task.subtasks).sorted { $0.sortOrder < $1.sortOrder }
            ForEach(subtasks) { sub in
                SubtaskRowView(subtask: sub)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .contextMenu {
            TaskRowContextMenuContent(
                isTopLevel: task.isTopLevel,
                isStarred: task.isStarred,
                onAddSubtask: addSubtask,
                onToggleStar: {
                    withAnimation { taskMutationService.toggleStar(for: task) }
                },
                onDeleteTask: {
                    withAnimation { taskMutationService.deleteTask(task) }
                }
            )
        }
    }

    private func addSubtask() {
        taskMutationService.addSubtask(title: "", to: task)
    }

    private func selectToday() {
        taskMutationService.updateDueDate(
            for: task,
            to: Calendar.current.startOfDay(for: Date())
        )
    }

    private func selectTomorrow() {
        taskMutationService.updateDueDate(
            for: task,
            to: Calendar.current.date(
                byAdding: .day,
                value: 1,
                to: Calendar.current.startOfDay(for: Date())
            )
        )
    }
}

private struct TaskRowContextMenuContent: View {
    let isTopLevel: Bool
    let isStarred: Bool
    let onAddSubtask: () -> Void
    let onToggleStar: () -> Void
    let onDeleteTask: () -> Void

    var body: some View {
        if isTopLevel {
            Button(action: onAddSubtask) {
                Label("サブタスクを追加", systemImage: "text.line.first.and.arrowtriangle.forward")
            }
        }

        Button(action: onToggleStar) {
            Label(
                isStarred ? "スターを外す" : "スターを付ける",
                systemImage: isStarred ? "star.slash" : "star"
            )
        }

        Divider()

        Button(role: .destructive, action: onDeleteTask) {
            Label("削除", systemImage: "trash")
        }
    }
}
