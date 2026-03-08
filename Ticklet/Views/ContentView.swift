import SwiftUI
import SwiftData

@MainActor
struct AddTaskActions {
    let addQuickTask: (String, TaskList?, Int) -> Void
}

@MainActor
struct CompletedTaskActions {
    let markIncomplete: (TaskItem) -> Void
    let deleteCompletedTask: (TaskItem) -> Void
}

@MainActor
struct SubtaskActions {
    let toggleSubtaskCompletion: (TaskItem) -> Void
    let deleteSubtask: (TaskItem) -> Void
}

@MainActor
struct TaskRowActions {
    let toggleTaskStar: (TaskItem) -> Void
    let setTaskDueDate: (TaskItem, Date?) -> Void
    let addSubtask: (TaskItem) -> Void
    let deleteTask: (TaskItem) -> Void
    let subtaskActions: SubtaskActions
}

@MainActor
struct ListPopoverActions {
    let createList: (String, Int) -> Void
    let renameList: (TaskList, String) -> Void
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.sortOrder) private var lists: [TaskList]
    @Query private var allTasks: [TaskItem]

    @State private var coordinator = ContentViewCoordinator()

    private var taskMutationService: TaskMutationService {
        TaskMutationService(modelContext: modelContext)
    }

    private var listMutationService: ListMutationService {
        ListMutationService(modelContext: modelContext)
    }

    private var addTaskActions: AddTaskActions {
        AddTaskActions { title, list, sortOrder in
            withAnimation {
                _ = taskMutationService.addTask(
                    title: title,
                    note: "",
                    dueDate: nil,
                    recurrenceRule: nil,
                    isStarred: false,
                    sortOrder: sortOrder,
                    list: list
                )
            }
        }
    }

    private var completedTaskActions: CompletedTaskActions {
        CompletedTaskActions(
            markIncomplete: { task in
                withAnimation {
                    taskMutationService.markTaskIncomplete(task)
                }
            },
            deleteCompletedTask: { task in
                withAnimation {
                    taskMutationService.deleteTask(task)
                }
            }
        )
    }

    private var subtaskActions: SubtaskActions {
        SubtaskActions(
            toggleSubtaskCompletion: { subtask in
                withAnimation {
                    taskMutationService.toggleSubtaskCompletion(subtask)
                }
            },
            deleteSubtask: { subtask in
                withAnimation {
                    taskMutationService.deleteTask(subtask)
                }
            }
        )
    }

    private var taskRowActions: TaskRowActions {
        TaskRowActions(
            toggleTaskStar: { task in
                withAnimation {
                    taskMutationService.toggleStar(for: task)
                }
            },
            setTaskDueDate: { task, dueDate in
                withAnimation {
                    taskMutationService.updateDueDate(for: task, to: dueDate)
                }
            },
            addSubtask: { task in
                withAnimation {
                    _ = taskMutationService.addSubtask(title: "", to: task)
                }
            },
            deleteTask: { task in
                withAnimation {
                    taskMutationService.deleteTask(task)
                }
            },
            subtaskActions: subtaskActions
        )
    }

    private var listPopoverActions: ListPopoverActions {
        ListPopoverActions(
            createList: { name, sortOrder in
                listMutationService.createList(name: name, sortOrder: sortOrder)
            },
            renameList: { list, name in
                listMutationService.renameList(list, to: name)
            }
        )
    }

    private func makeProjection() -> ContentViewProjection {
        ContentViewProjection(
            lists: lists,
            allTasks: allTasks,
            selectedListID: coordinator.selectedListID,
            filterMode: coordinator.filterMode
        )
    }

    var body: some View {
        let projection = makeProjection()

        ContentViewScene(
            lists: lists,
            projection: projection,
            coordinator: coordinator,
            onAppear: initializeDefaultList,
            onCompleteTask: completeTask,
            onDeleteCompleted: deleteCompleted,
            onConfirmDeleteList: confirmDeleteList,
            addTaskActions: addTaskActions,
            completedTaskActions: completedTaskActions,
            taskRowActions: taskRowActions,
            listPopoverActions: listPopoverActions
        )
    }

    private func initializeDefaultList() {
        coordinator.bootstrap(using: listMutationService, existingLists: lists)
    }

    private func completeTask(_ task: TaskItem) {
        withAnimation {
            taskMutationService.completeTask(task)
        }
    }

    private func deleteCompleted(_ tasks: [TaskItem]) {
        withAnimation {
            taskMutationService.deleteCompletedTasks(tasks)
        }
    }

    private func confirmDeleteList() {
        withAnimation {
            coordinator.confirmDeleteList(using: listMutationService, existingLists: lists)
        }
    }
}

private struct ContentViewScene: View {
    let lists: [TaskList]
    let projection: ContentViewProjection
    let coordinator: ContentViewCoordinator
    let onAppear: () -> Void
    let onCompleteTask: (TaskItem) -> Void
    let onDeleteCompleted: ([TaskItem]) -> Void
    let onConfirmDeleteList: () -> Void
    let addTaskActions: AddTaskActions
    let completedTaskActions: CompletedTaskActions
    let taskRowActions: TaskRowActions
    let listPopoverActions: ListPopoverActions

    var body: some View {
        @Bindable var coordinator = coordinator

        ContentViewLayout(
            projection: projection,
            coordinator: coordinator,
            onCompleteTask: onCompleteTask,
            onDeleteCompleted: onDeleteCompleted,
            addTaskActions: addTaskActions,
            completedTaskActions: completedTaskActions,
            taskRowActions: taskRowActions
        )
        .frame(width: 320, height: 480)
        .onAppear(perform: onAppear)
        .popover(isPresented: $coordinator.isPresentingCreateList) {
            CreateListPopover(
                isPresented: $coordinator.isPresentingCreateList,
                existingCount: lists.count,
                actions: listPopoverActions
            )
        }
        .popover(isPresented: $coordinator.isPresentingRenameList) {
            if let list = coordinator.listToRename {
                RenameListPopover(
                    list: list,
                    isPresented: $coordinator.isPresentingRenameList,
                    actions: listPopoverActions
                )
            }
        }
        .alert(
            "リストを削除しますか？",
            isPresented: $coordinator.isPresentingDeleteConfirm,
            presenting: coordinator.listToDelete
        ) { _ in
            Button("削除", role: .destructive, action: onConfirmDeleteList)
            Button("キャンセル", role: .cancel) {
                coordinator.dismissDeleteConfirm()
            }
        } message: { _ in
            Text("このリストとすべてのタスクが削除されます。")
        }
        .onChange(of: coordinator.isPresentingRenameList) { _, isPresented in
            if !isPresented, coordinator.listToRename != nil {
                coordinator.dismissRenameList()
            }
        }
        .onChange(of: coordinator.isPresentingDeleteConfirm) { _, isPresented in
            if !isPresented, coordinator.listToDelete != nil {
                coordinator.dismissDeleteConfirm()
            }
        }
        .onKeyPress(.escape) {
            coordinator.handleEscapeKeyPress() ? .handled : .ignored
        }
    }
}

private struct ContentViewLayout: View {
    let projection: ContentViewProjection
    let coordinator: ContentViewCoordinator
    let onCompleteTask: (TaskItem) -> Void
    let onDeleteCompleted: ([TaskItem]) -> Void
    let addTaskActions: AddTaskActions
    let completedTaskActions: CompletedTaskActions
    let taskRowActions: TaskRowActions

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(
                lists: projection.sortedLists,
                selectedListID: coordinator.selectedListID,
                selectedListName: projection.selectedListName,
                selectedList: projection.selectedList,
                filterMode: coordinator.filterMode,
                onSelectList: coordinator.selectList,
                onToggleFilterMode: coordinator.toggleFilterMode,
                onCreateList: coordinator.presentCreateList,
                onRenameList: coordinator.presentRenameList,
                onDeleteList: coordinator.presentDeleteList,
                onDeleteCompleted: {
                    onDeleteCompleted(projection.completedTasks)
                },
                onSortChanged: { option in
                    projection.selectedList?.sort = option
                },
                currentSort: projection.currentSort
            )

            Divider()

            AddTaskView(
                list: projection.selectedList,
                nextSortOrder: projection.nextSortOrder,
                actions: addTaskActions
            )

            Divider()

            TaskListContentView(
                projection: projection,
                expandedTaskID: coordinator.expandedTaskID,
                onTapTask: toggleExpandedTask,
                onCompleteTask: onCompleteTask,
                completedTaskActions: completedTaskActions,
                taskRowActions: taskRowActions,
                onDeleteCompleted: {
                    onDeleteCompleted(projection.completedTasks)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func toggleExpandedTask(_ task: TaskItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            coordinator.toggleExpandedTask(task.id)
        }
    }
}

private struct TaskListContentView: View {
    let projection: ContentViewProjection
    let expandedTaskID: UUID?
    let onTapTask: (TaskItem) -> Void
    let onCompleteTask: (TaskItem) -> Void
    let completedTaskActions: CompletedTaskActions
    let taskRowActions: TaskRowActions
    let onDeleteCompleted: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                TaskSectionListView(
                    projection: projection,
                    expandedTaskID: expandedTaskID,
                    onTapTask: onTapTask,
                    onCompleteTask: onCompleteTask,
                    taskRowActions: taskRowActions
                )

                CompletedTasksSection(
                    tasks: projection.completedTasks,
                    onDeleteAll: onDeleteCompleted,
                    actions: completedTaskActions
                )
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TaskList.self, TaskItem.self], inMemory: true)
}
