import SwiftUI
import SwiftData

struct CreateListPopover: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    let existingCount: Int

    @State private var name = ""

    private var listMutationService: ListMutationService {
        ListMutationService(modelContext: modelContext)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("新しいリスト")
                .font(.headline)

            TextField("リスト名", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit { create() }

            HStack {
                Button("キャンセル") { isPresented = false }
                Spacer()
                Button("作成") { create() }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 240)
    }

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        listMutationService.createList(name: trimmed, sortOrder: existingCount)
        isPresented = false
    }
}

struct RenameListPopover: View {
    @Bindable var list: TaskList
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool

    @State private var name: String = ""

    private var listMutationService: ListMutationService {
        ListMutationService(modelContext: modelContext)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("リスト名を変更")
                .font(.headline)

            TextField("リスト名", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit { rename() }

            HStack {
                Button("キャンセル") { isPresented = false }
                Spacer()
                Button("変更") { rename() }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 240)
        .onAppear { name = list.name }
    }

    private func rename() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        listMutationService.renameList(list, to: trimmed)
        isPresented = false
    }
}
