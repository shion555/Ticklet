import SwiftUI
import SwiftData

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

    private func makeReadModel() -> ContentViewReadModel {
        ContentViewReadModel(
            lists: lists,
            allTasks: allTasks,
            selectedListID: coordinator.selectedListID,
            filterMode: coordinator.filterMode
        )
    }

    var body: some View {
        let readModel = makeReadModel()

        ContentViewScene(
            lists: lists,
            readModel: readModel,
            coordinator: coordinator,
            onAppear: initializeDefaultList,
            onCompleteTask: completeTask,
            onDeleteCompleted: deleteCompleted,
            onConfirmDeleteList: confirmDeleteList
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
    let readModel: ContentViewReadModel
    let coordinator: ContentViewCoordinator
    let onAppear: () -> Void
    let onCompleteTask: (TaskItem) -> Void
    let onDeleteCompleted: ([TaskItem]) -> Void
    let onConfirmDeleteList: () -> Void

    var body: some View {
        @Bindable var coordinator = coordinator

        ContentViewLayout(
            readModel: readModel,
            coordinator: coordinator,
            onCompleteTask: onCompleteTask,
            onDeleteCompleted: onDeleteCompleted
        )
        .frame(width: 320, height: 480)
        .onAppear(perform: onAppear)
        .popover(isPresented: $coordinator.isPresentingCreateList) {
            CreateListPopover(
                isPresented: $coordinator.isPresentingCreateList,
                existingCount: lists.count
            )
        }
        .popover(isPresented: $coordinator.isPresentingRenameList) {
            if let list = coordinator.listToRename {
                RenameListPopover(
                    list: list,
                    isPresented: $coordinator.isPresentingRenameList
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
    let readModel: ContentViewReadModel
    let coordinator: ContentViewCoordinator
    let onCompleteTask: (TaskItem) -> Void
    let onDeleteCompleted: ([TaskItem]) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(
                lists: readModel.sortedLists,
                selectedListID: coordinator.selectedListID,
                selectedListName: readModel.selectedListName,
                selectedList: readModel.selectedList,
                filterMode: coordinator.filterMode,
                onSelectList: coordinator.selectList,
                onToggleFilterMode: coordinator.toggleFilterMode,
                onCreateList: coordinator.presentCreateList,
                onRenameList: coordinator.presentRenameList,
                onDeleteList: coordinator.presentDeleteList,
                onDeleteCompleted: {
                    onDeleteCompleted(readModel.completedTasks)
                },
                onSortChanged: { option in
                    readModel.selectedList?.sort = option
                },
                currentSort: readModel.currentSort
            )

            Divider()

            AddTaskView(list: readModel.selectedList, nextSortOrder: readModel.nextSortOrder)

            Divider()

            TaskListContentView(
                readModel: readModel,
                expandedTaskID: coordinator.expandedTaskID,
                onTapTask: toggleExpandedTask,
                onCompleteTask: onCompleteTask,
                onDeleteCompleted: {
                    onDeleteCompleted(readModel.completedTasks)
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
    let readModel: ContentViewReadModel
    let expandedTaskID: UUID?
    let onTapTask: (TaskItem) -> Void
    let onCompleteTask: (TaskItem) -> Void
    let onDeleteCompleted: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                TaskSectionListView(
                    readModel: readModel,
                    expandedTaskID: expandedTaskID,
                    onTapTask: onTapTask,
                    onCompleteTask: onCompleteTask
                )

                CompletedTasksSection(tasks: readModel.completedTasks, onDeleteAll: onDeleteCompleted)
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
