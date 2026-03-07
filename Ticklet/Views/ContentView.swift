import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskList.sortOrder) private var lists: [TaskList]
    @Query private var allTasks: [TaskItem]

    @State private var selectedListID: UUID?
    @State private var filterMode: FilterMode = .all
    @State private var expandedTaskID: UUID?

    @State private var showCreateList = false
    @State private var showRenameList = false
    @State private var listToRename: TaskList?
    @State private var showDeleteConfirm = false
    @State private var listToDelete: TaskList?

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
            selectedListID: selectedListID,
            filterMode: filterMode
        )
    }

    var body: some View {
        let readModel = makeReadModel()

        VStack(spacing: 0) {
            HeaderView(
                selectedListID: $selectedListID,
                filterMode: $filterMode,
                lists: readModel.sortedLists,
                selectedListName: readModel.selectedListName,
                selectedList: readModel.selectedList,
                onCreateList: { showCreateList = true },
                onRenameList: { list in
                    listToRename = list
                    showRenameList = true
                },
                onDeleteList: { list in
                    listToDelete = list
                    showDeleteConfirm = true
                },
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

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if readModel.showsGroupedActiveTasks {
                        groupedByDate(readModel)
                    } else {
                        flatList(readModel)
                    }

                    CompletedTasksSection(tasks: readModel.completedTasks) {
                        deleteCompleted(readModel.completedTasks)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
            }
        }
        .frame(width: 320, height: 480)
        .onAppear { initializeDefaultList() }
        .popover(isPresented: $showCreateList) {
            CreateListPopover(isPresented: $showCreateList, existingCount: lists.count)
        }
        .popover(isPresented: $showRenameList) {
            if let list = listToRename {
                RenameListPopover(list: list, isPresented: $showRenameList)
            }
        }
        .alert("リストを削除しますか？", isPresented: $showDeleteConfirm) {
            Button("削除", role: .destructive) {
                if let list = listToDelete {
                    withAnimation {
                        listMutationService.deleteList(list)
                        if selectedListID == list.id {
                            selectedListID = listMutationService.fallbackSelectedListID(
                                afterDeleting: list,
                                remainingLists: lists
                            )
                        }
                    }
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("このリストとすべてのタスクが削除されます。")
        }
        .onKeyPress(.escape) {
            if expandedTaskID != nil {
                expandedTaskID = nil
                return .handled
            }
            return .ignored
        }
    }

    // MARK: - Flat list
    @ViewBuilder
    private func flatList(_ readModel: ContentViewReadModel) -> some View {
        ForEach(readModel.activeTasks) { task in
            taskRow(task)
            Divider().padding(.leading, 12)
        }
    }

    // MARK: - Grouped by date
    @ViewBuilder
    private func groupedByDate(_ readModel: ContentViewReadModel) -> some View {
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

    // MARK: - Task Row
    private func taskRow(_ task: TaskItem) -> some View {
        TaskRowView(
            task: task,
            isExpanded: expandedTaskID == task.id,
            onTap: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedTaskID = expandedTaskID == task.id ? nil : task.id
                }
            },
            onComplete: {
                completeTask(task)
            }
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }

    // MARK: - Actions
    private func initializeDefaultList() {
        if let defaultList = listMutationService.initializeDefaultList(existingLists: lists), lists.isEmpty {
            selectedListID = defaultList.id
        } else if selectedListID == nil {
            selectedListID = lists.first(where: { $0.isDefault })?.id ?? lists.first?.id
        }
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

#Preview {
    ContentView()
        .modelContainer(for: [TaskList.self, TaskItem.self], inMemory: true)
}
