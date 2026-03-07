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

    private var selectedList: TaskList? {
        lists.first { $0.id == selectedListID }
    }

    private var currentSort: SortOption {
        selectedList?.sort ?? .manual
    }

    private var activeTasks: [TaskItem] {
        var tasks: [TaskItem]
        if filterMode == .starred {
            tasks = allTasks.filter { $0.isTopLevel && !$0.isCompleted && $0.isStarred }
        } else {
            tasks = allTasks.filter { $0.isTopLevel && !$0.isCompleted && $0.list?.id == selectedListID }
        }
        return sortedTasks(tasks)
    }

    private var completedTasks: [TaskItem] {
        if filterMode == .starred {
            return allTasks.filter { $0.isTopLevel && $0.isCompleted && $0.isStarred }
        }
        return allTasks.filter { $0.isTopLevel && $0.isCompleted && $0.list?.id == selectedListID }
    }

    private var nextSortOrder: Int {
        (activeTasks.map(\.sortOrder).max() ?? -1) + 1
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(
                selectedListID: $selectedListID,
                filterMode: $filterMode,
                lists: lists,
                onCreateList: { showCreateList = true },
                onRenameList: { list in
                    listToRename = list
                    showRenameList = true
                },
                onDeleteList: { list in
                    listToDelete = list
                    showDeleteConfirm = true
                },
                onDeleteCompleted: deleteCompleted,
                onSortChanged: { option in
                    selectedList?.sort = option
                },
                currentSort: currentSort
            )

            Divider()

            AddTaskView(list: selectedList, nextSortOrder: nextSortOrder)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if currentSort == .dueDate || currentSort == .date {
                        groupedByDate
                    } else {
                        flatList
                    }

                    CompletedTasksSection(tasks: completedTasks) {
                        deleteCompleted()
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
                        modelContext.delete(list)
                        if selectedListID == list.id {
                            selectedListID = lists.first(where: { $0.isDefault })?.id
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
    private var flatList: some View {
        ForEach(activeTasks) { task in
            taskRow(task)
            Divider().padding(.leading, 12)
        }
    }

    // MARK: - Grouped by date
    @ViewBuilder
    private var groupedByDate: some View {
        let grouped = Dictionary(grouping: activeTasks) { DateSection.section(for: $0.dueDate) }
        let sections = grouped.keys.sorted()

        ForEach(sections, id: \.title) { section in
            Text(section.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 2)

            ForEach(grouped[section] ?? []) { task in
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
        if lists.isEmpty {
            let defaultList = TaskList(name: "マイタスク", sortOrder: 0, isDefault: true)
            modelContext.insert(defaultList)
            try? modelContext.save()
            selectedListID = defaultList.id
        } else if selectedListID == nil {
            selectedListID = lists.first(where: { $0.isDefault })?.id ?? lists.first?.id
        }
    }

    private func completeTask(_ task: TaskItem) {
        withAnimation {
            task.isCompleted.toggle()
            task.completedAt = task.isCompleted ? Date() : nil

            if task.isCompleted, let rule = task.recurrenceRule {
                let nextDate = RecurrenceHelper.nextDate(from: task.dueDate, rule: rule)
                let newTask = TaskItem(
                    title: task.title,
                    details: task.details,
                    dueDate: nextDate,
                    isStarred: task.isStarred,
                    sortOrder: task.sortOrder,
                    list: task.list
                )
                newTask.recurrenceRule = rule
                modelContext.insert(newTask)
            }
        }
    }

    private func deleteCompleted() {
        withAnimation {
            for task in completedTasks {
                modelContext.delete(task)
            }
        }
    }

    private func sortedTasks(_ tasks: [TaskItem]) -> [TaskItem] {
        switch currentSort {
        case .manual:
            return tasks.sorted { $0.sortOrder < $1.sortOrder }
        case .date:
            return tasks.sorted { $0.createdAt > $1.createdAt }
        case .dueDate:
            return tasks.sorted { t1, t2 in
                switch (t1.dueDate, t2.dueDate) {
                case (nil, nil): return t1.createdAt < t2.createdAt
                case (nil, _): return false
                case (_, nil): return true
                case (let d1?, let d2?): return d1 < d2
                }
            }
        case .title:
            return tasks.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TaskList.self, TaskItem.self], inMemory: true)
}
