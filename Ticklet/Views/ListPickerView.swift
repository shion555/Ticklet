import SwiftUI

struct ListPickerView: View {
    let lists: [TaskList]
    let selectedListID: UUID?
    let selectedListName: String
    let onSelectList: (UUID?) -> Void
    let onCreateList: () -> Void

    var body: some View {
        Menu {
            ForEach(lists) { list in
                Button {
                    onSelectList(list.id)
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
                Text(selectedListName)
                    .font(.headline)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
        }
        .accessibilityIdentifier("header-list-picker")
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
