import SwiftUI

struct TaskRowView: View {
    @Bindable var task: TaskItem
    let isExpanded: Bool
    let onTap: () -> Void
    let onComplete: () -> Void
    let actions: TaskRowActions

    @State private var isHovering = false
    @FocusState private var titleFocused: Bool
    @FocusState private var detailsFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TaskRowHeaderView(
                taskID: task.id,
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
                    actions.toggleTaskStar(task)
                },
                onUpdateDueDate: { newDate in
                    actions.setTaskDueDate(task, newDate)
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
                    onSelectToday: { selectToday() },
                    onSelectTomorrow: { selectTomorrow() },
                    onUpdateDueDate: { newDate in
                        actions.setTaskDueDate(task, newDate)
                    }
                )
            }

            TaskRowSubtasksView(subtasks: task.subtasks, actions: actions.subtaskActions)
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
                    actions.toggleTaskStar(task)
                },
                onDeleteTask: {
                    actions.deleteTask(task)
                }
            )
        }
    }

    private func addSubtask() {
        actions.addSubtask(task)
    }

    private func selectToday() {
        actions.setTaskDueDate(task, Calendar.current.startOfDay(for: Date()))
    }

    private func selectTomorrow() {
        actions.setTaskDueDate(
            task,
            Calendar.current.date(
                byAdding: .day,
                value: 1,
                to: Calendar.current.startOfDay(for: Date())
            )
        )
    }
}

private struct TaskRowSubtasksView: View {
    let subtasks: [TaskItem]
    let actions: SubtaskActions

    var body: some View {
        ForEach(subtasks.sorted { $0.sortOrder < $1.sortOrder }) { subtask in
            SubtaskRowView(subtask: subtask, actions: actions)
        }
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
