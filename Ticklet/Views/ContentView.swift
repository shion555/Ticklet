import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.sortOrder) private var lists: [TaskList]
    @Query private var allTasks: [TaskItem]

    @State private var viewModel = ContentViewStateViewModel()

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
            selectedListID: viewModel.selectedListID,
            filterMode: viewModel.filterMode
        )
    }

    var body: some View {
        let readModel = makeReadModel()

        VStack(spacing: 0) {
            HeaderView(
                lists: readModel.sortedLists,
                selectedListID: viewModel.selectedListID,
                selectedListName: readModel.selectedListName,
                selectedList: readModel.selectedList,
                filterMode: viewModel.filterMode,
                onSelectList: viewModel.selectList,
                onToggleFilterMode: viewModel.toggleFilterMode,
                onCreateList: viewModel.presentCreateList,
                onRenameList: viewModel.presentRenameList,
                onDeleteList: viewModel.presentDeleteList,
                onDeleteCompleted: {
                    deleteCompleted(readModel.completedTasks)
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
                expandedTaskID: viewModel.expandedTaskID,
                onTapTask: toggleExpandedTask,
                onCompleteTask: completeTask,
                onDeleteCompleted: {
                    deleteCompleted(readModel.completedTasks)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 320, height: 480)
        .onAppear {
            initializeDefaultList()
        }
        .popover(isPresented: $viewModel.showCreateList) {
            CreateListPopover(
                isPresented: Binding(
                    get: { viewModel.showCreateList },
                    set: { newValue in
                        if newValue {
                            viewModel.showCreateList = true
                        } else {
                            viewModel.dismissCreateList()
                        }
                    }
                ),
                existingCount: lists.count
            )
        }
        .popover(isPresented: $viewModel.showRenameList) {
            if let list = viewModel.listToRename {
                RenameListPopover(
                    list: list,
                    isPresented: Binding(
                        get: { viewModel.showRenameList },
                        set: { newValue in
                            if newValue {
                                viewModel.showRenameList = true
                            } else {
                                viewModel.dismissRenameList()
                            }
                        }
                    )
                )
            }
        }
        .alert("リストを削除しますか？", isPresented: $viewModel.showDeleteConfirm) {
            Button("削除", role: .destructive) {
                if let list = viewModel.listToDelete {
                    withAnimation {
                        listMutationService.deleteList(list)
                        let fallbackSelectedListID = listMutationService.fallbackSelectedListID(
                            afterDeleting: list,
                            remainingLists: lists
                        )
                        viewModel.applyListDeletionFallback(
                            currentDeletedListID: list.id,
                            fallbackSelectedListID: fallbackSelectedListID
                        )
                        viewModel.dismissDeleteConfirm()
                    }
                }
            }
            Button("キャンセル", role: .cancel) {
                viewModel.dismissDeleteConfirm()
            }
        } message: {
            Text("このリストとすべてのタスクが削除されます。")
        }
        .onKeyPress(.escape) {
            if viewModel.expandedTaskID != nil {
                viewModel.collapseExpandedTask()
                return .handled
            }
            return .ignored
        }
    }

    private func toggleExpandedTask(_ task: TaskItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.toggleExpandedTask(task.id)
        }
    }

    // MARK: - Actions
    private func initializeDefaultList() {
        let defaultList = listMutationService.initializeDefaultList(existingLists: lists)
        let defaultListID = defaultList?.id ?? lists.first(where: \.isDefault)?.id
        viewModel.syncInitialSelection(with: lists, defaultListID: defaultListID)
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
