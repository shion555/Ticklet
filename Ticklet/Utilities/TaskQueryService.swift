import Foundation

enum TaskQueryService {
    static func activeTasks(
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

    static func completedTasks(
        from allTasks: [TaskItem],
        selectedListID: UUID?,
        filterMode: FilterMode
    ) -> [TaskItem] {
        if filterMode == .starred {
            return allTasks.filter { $0.isTopLevel && $0.isCompleted && $0.isStarred }
        }

        return allTasks.filter { $0.isTopLevel && $0.isCompleted && $0.list?.id == selectedListID }
    }

    static func sort(_ tasks: [TaskItem], by sortOption: SortOption) -> [TaskItem] {
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
