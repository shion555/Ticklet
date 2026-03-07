import SwiftUI

struct HeaderView: View {
    let lists: [TaskList]
    let selectedListID: UUID?
    let selectedListName: String
    let selectedList: TaskList?
    let filterMode: FilterMode
    let onSelectList: (UUID?) -> Void
    let onToggleFilterMode: () -> Void
    let onCreateList: () -> Void
    let onRenameList: (TaskList) -> Void
    let onDeleteList: (TaskList) -> Void
    let onDeleteCompleted: () -> Void
    let onSortChanged: (SortOption) -> Void
    let currentSort: SortOption

    var body: some View {
        HStack(spacing: 8) {
            ListPickerView(
                lists: lists,
                selectedListID: selectedListID,
                selectedListName: selectedListName,
                onSelectList: onSelectList,
                onCreateList: onCreateList
            )

            Spacer()

            FilterToggleButton(filterMode: filterMode, onToggle: onToggleFilterMode)

            HeaderActionsMenuView(
                selectedList: selectedList,
                currentSort: currentSort,
                onSortChanged: onSortChanged,
                onRenameList: onRenameList,
                onDeleteList: onDeleteList,
                onDeleteCompleted: onDeleteCompleted
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
