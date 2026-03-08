import Foundation

struct ContentViewProjection {
    let selectedList: TaskList?
    let selectedListID: UUID?
    let selectedListName: String
    let currentSort: SortOption
    let activeTasks: [TaskItem]
    let completedTasks: [TaskItem]
    let nextSortOrder: Int
    let showsGroupedActiveTasks: Bool
    let groupedActiveTasks: [(section: DateSection, tasks: [TaskItem])]
    let sortedLists: [TaskList]
    let renameableSelectedList: TaskList?

    init(
        lists: [TaskList],
        allTasks: [TaskItem],
        selectedListID: UUID?,
        filterMode: FilterMode,
        calendar: Calendar = .current,
        now: Date = Date()
    ) {
        self.selectedListID = selectedListID

        let sortedLists = lists.sorted { $0.sortOrder < $1.sortOrder }
        self.sortedLists = sortedLists

        let selectedList = sortedLists.first { $0.id == selectedListID }
        self.selectedList = selectedList
        self.selectedListName = selectedList?.name ?? "マイタスク"

        let currentSort = selectedList?.sort ?? .manual
        self.currentSort = currentSort

        let activeTasks = Self.activeTasks(
            from: allTasks,
            selectedListID: selectedListID,
            filterMode: filterMode,
            sortOption: currentSort
        )
        self.activeTasks = activeTasks

        self.completedTasks = Self.completedTasks(
            from: allTasks,
            selectedListID: selectedListID,
            filterMode: filterMode
        )

        self.nextSortOrder = (activeTasks.map(\.sortOrder).max() ?? -1) + 1
        let showsGroupedActiveTasks = currentSort == .dueDate || currentSort == .date
        self.showsGroupedActiveTasks = showsGroupedActiveTasks
        self.groupedActiveTasks = showsGroupedActiveTasks
            ? Self.groupedByDate(activeTasks, calendar: calendar, now: now)
            : []
        self.renameableSelectedList = (selectedList?.isDefault == false) ? selectedList : nil
    }

    private static func activeTasks(
        from allTasks: [TaskItem],
        selectedListID: UUID?,
        filterMode: FilterMode,
        sortOption: SortOption
    ) -> [TaskItem] {
        let filtered: [TaskItem]
        if filterMode == .starred {
            filtered = allTasks.filter { $0.isTopLevel && !$0.isCompleted && $0.isStarred }
        } else {
            filtered = allTasks.filter { $0.isTopLevel && !$0.isCompleted && $0.list?.id == selectedListID }
        }

        return sort(filtered, by: sortOption)
    }

    private static func completedTasks(
        from allTasks: [TaskItem],
        selectedListID: UUID?,
        filterMode: FilterMode
    ) -> [TaskItem] {
        if filterMode == .starred {
            return allTasks.filter { $0.isTopLevel && $0.isCompleted && $0.isStarred }
        }

        return allTasks.filter { $0.isTopLevel && $0.isCompleted && $0.list?.id == selectedListID }
    }

    private static func sort(_ tasks: [TaskItem], by sortOption: SortOption) -> [TaskItem] {
        switch sortOption {
        case .manual:
            return tasks.sorted { $0.sortOrder < $1.sortOrder }
        case .date:
            return tasks.sorted { $0.createdAt > $1.createdAt }
        case .dueDate:
            return tasks.sorted { lhs, rhs in
                switch (lhs.dueDate, rhs.dueDate) {
                case (nil, nil):
                    return lhs.createdAt < rhs.createdAt
                case (nil, _):
                    return false
                case (_, nil):
                    return true
                case (let left?, let right?):
                    return left < right
                }
            }
        case .title:
            return tasks.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        }
    }

    static func groupedByDate(
        _ tasks: [TaskItem],
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [(section: DateSection, tasks: [TaskItem])] {
        let grouped = Dictionary(grouping: tasks) {
            DateSection.section(for: $0.dueDate, calendar: calendar, now: now)
        }

        return grouped.keys.sorted().map { section in
            (section: section, tasks: grouped[section] ?? [])
        }
    }
}
