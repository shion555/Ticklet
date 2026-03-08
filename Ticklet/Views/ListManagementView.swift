import SwiftUI

struct CreateListPopover: View {
    @Binding var isPresented: Bool
    let existingCount: Int
    let actions: ListPopoverActions

    @State private var name = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("新しいリスト")
                .font(.headline)

            TextField("リスト名", text: $name)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("create-list-field")
                .onSubmit { create() }

            HStack {
                Button("キャンセル") { isPresented = false }
                Spacer()
                Button("作成") { create() }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityIdentifier("create-list-submit")
            }
        }
        .padding()
        .frame(width: 240)
    }

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        actions.createList(trimmed, existingCount)
        isPresented = false
    }
}

struct RenameListPopover: View {
    @Bindable var list: TaskList
    @Binding var isPresented: Bool
    let actions: ListPopoverActions

    @State private var name: String = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("リスト名を変更")
                .font(.headline)

            TextField("リスト名", text: $name)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("rename-list-field")
                .onSubmit { rename() }

            HStack {
                Button("キャンセル") { isPresented = false }
                Spacer()
                Button("変更") { rename() }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityIdentifier("rename-list-submit")
            }
        }
        .padding()
        .frame(width: 240)
        .onAppear { name = list.name }
    }

    private func rename() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        actions.renameList(list, trimmed)
        isPresented = false
    }
}
