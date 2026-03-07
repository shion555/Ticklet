import SwiftUI

struct HeaderActionsMenuView: View {
    let selectedList: TaskList?
    let currentSort: SortOption
    let onSortChanged: (SortOption) -> Void
    let onRenameList: (TaskList) -> Void
    let onDeleteList: (TaskList) -> Void
    let onDeleteCompleted: () -> Void

    var body: some View {
        Menu {
            Section("並べ替え") {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button {
                        onSortChanged(option)
                    } label: {
                        HStack {
                            Text(option.displayName)
                            if currentSort == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Divider()

            if let list = selectedList, !list.isDefault {
                Button {
                    onRenameList(list)
                } label: {
                    Label("リスト名を変更", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    onDeleteList(list)
                } label: {
                    Label("リストを削除", systemImage: "trash")
                }

                Divider()
            }

            Button(role: .destructive) {
                onDeleteCompleted()
            } label: {
                Label("完了タスクをすべて削除", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .accessibilityIdentifier("header-actions-menu")
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
