import SwiftUI
import SwiftData

struct HeaderView: View {
    @Binding var selectedListID: UUID?
    @Binding var filterMode: FilterMode
    let lists: [TaskList]
    let onCreateList: () -> Void
    let onRenameList: (TaskList) -> Void
    let onDeleteList: (TaskList) -> Void
    let onDeleteCompleted: () -> Void
    let onSortChanged: (SortOption) -> Void
    let currentSort: SortOption

    var selectedList: TaskList? {
        lists.first { $0.id == selectedListID }
    }

    var body: some View {
        HStack(spacing: 8) {
            // List picker
            Menu {
                ForEach(lists.sorted(by: { $0.sortOrder < $1.sortOrder })) { list in
                    Button {
                        selectedListID = list.id
                    } label: {
                        HStack {
                            Text(list.name)
                            if list.id == selectedListID {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                Divider()
                Button {
                    onCreateList()
                } label: {
                    Label("新しいリスト", systemImage: "plus")
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedList?.name ?? "マイタスク")
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Spacer()

            // Star filter
            Button {
                withAnimation {
                    filterMode = filterMode == .all ? .starred : .all
                }
            } label: {
                Image(systemName: filterMode == .starred ? "star.fill" : "star")
                    .foregroundStyle(filterMode == .starred ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .help(filterMode == .starred ? "すべてのタスク" : "スター付き")

            // Sort & options menu
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
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
