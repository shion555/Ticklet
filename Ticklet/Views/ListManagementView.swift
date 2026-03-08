import SwiftUI

struct CreateListPopover: View {
    @Binding var isPresented: Bool
    let existingCount: Int
    let actions: ListPopoverActions

    @State private var name = ""

    var body: some View {
        ListEditorPopover(
            title: "新しいリスト",
            submitLabel: "作成",
            name: $name,
            isPresented: $isPresented,
            fieldAccessibilityIdentifier: "create-list-field",
            submitAccessibilityIdentifier: "create-list-submit",
            onSubmit: create
        )
    }

    private func create() {
        actions.createList(name, existingCount)
    }
}

struct RenameListPopover: View {
    @Bindable var list: TaskList
    @Binding var isPresented: Bool
    let actions: ListPopoverActions

    @State private var name: String = ""

    var body: some View {
        let initialName = list.name

        ListEditorPopover(
            title: "リスト名を変更",
            submitLabel: "変更",
            name: $name,
            isPresented: $isPresented,
            fieldAccessibilityIdentifier: "rename-list-field",
            submitAccessibilityIdentifier: "rename-list-submit",
            onSubmit: rename
        )
        .onAppear {
            name = initialName
        }
        .onChange(of: initialName) { _, newValue in
            name = newValue
        }
    }

    private func rename() {
        actions.renameList(list, name)
    }
}

private struct ListEditorPopover: View {
    let title: String
    let submitLabel: String
    @Binding var name: String
    @Binding var isPresented: Bool
    let fieldAccessibilityIdentifier: String
    let submitAccessibilityIdentifier: String
    let onSubmit: () -> Void

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)

            TextField("リスト名", text: $name)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(fieldAccessibilityIdentifier)
                .onSubmit { submit() }

            HStack {
                Button("キャンセル") { isPresented = false }
                Spacer()
                Button(submitLabel) { submit() }
                    .buttonStyle(.borderedProminent)
                    .disabled(trimmedName.isEmpty)
                    .accessibilityIdentifier(submitAccessibilityIdentifier)
            }
        }
        .padding()
        .frame(width: 240)
    }

    private func submit() {
        name = trimmedName
        guard !name.isEmpty else { return }
        onSubmit()
        isPresented = false
    }
}
