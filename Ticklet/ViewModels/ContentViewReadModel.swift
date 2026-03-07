import Foundation

struct ContentViewReadModel {
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
        filterMode: FilterMode
    ) {
        self.selectedListID = selectedListID

        let sortedLists = TaskQueryService.sortedLists(lists)
        self.sortedLists = sortedLists

        let selectedList = TaskQueryService.selectedList(from: sortedLists, selectedListID: selectedListID)
        self.selectedList = selectedList
        self.selectedListName = selectedList?.name ?? "マイタスク"

        let currentSort = TaskQueryService.selectedSort(from: selectedList)
        self.currentSort = currentSort

        let activeTasks = TaskQueryService.activeTasks(
            from: allTasks,
            selectedListID: selectedListID,
            filterMode: filterMode,
            sortOption: currentSort
        )
        self.activeTasks = activeTasks

        self.completedTasks = TaskQueryService.completedTasks(
            from: allTasks,
            selectedListID: selectedListID,
            filterMode: filterMode
        )

        self.nextSortOrder = TaskQueryService.nextSortOrder(for: activeTasks)
        let showsGroupedActiveTasks = currentSort == .dueDate || currentSort == .date
        self.showsGroupedActiveTasks = showsGroupedActiveTasks
        self.groupedActiveTasks = showsGroupedActiveTasks
            ? TaskQueryService.groupedByDate(activeTasks)
            : []
        self.renameableSelectedList = (selectedList?.isDefault == false) ? selectedList : nil
    }
}
