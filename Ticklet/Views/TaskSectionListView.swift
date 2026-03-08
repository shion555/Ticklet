import SwiftUI

struct TaskSectionListView: View {
    let readModel: ContentViewReadModel
    let expandedTaskID: UUID?
    let onTapTask: (TaskItem) -> Void
    let onCompleteTask: (TaskItem) -> Void
    let taskRowActions: TaskRowActions

    var body: some View {
        if readModel.showsGroupedActiveTasks {
            groupedList
        } else {
            flatList
        }
    }

    @ViewBuilder
    private var flatList: some View {
        ForEach(readModel.activeTasks) { task in
            taskRow(task)
            Divider().padding(.leading, 12)
        }
    }

    @ViewBuilder
    private var groupedList: some View {
        ForEach(readModel.groupedActiveTasks, id: \.section) { group in
            Text(TaskDatePresentation.sectionTitle(for: group.section))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 2)

            ForEach(group.tasks) { task in
                taskRow(task)
                Divider().padding(.leading, 12)
            }
        }
    }

    private func taskRow(_ task: TaskItem) -> some View {
        TaskRowView(
            task: task,
            isExpanded: expandedTaskID == task.id,
            onTap: { onTapTask(task) },
            onComplete: { onCompleteTask(task) },
            actions: taskRowActions
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }
}
