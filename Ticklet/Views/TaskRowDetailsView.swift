import SwiftUI

struct TaskRowDetailsView: View {
    @Binding var details: String
    @Binding var recurrenceRule: RecurrenceRule?
    let dueDate: Date?
    let detailsFocused: FocusState<Bool>.Binding
    let onSelectToday: () -> Void
    let onSelectTomorrow: () -> Void
    let onUpdateDueDate: (Date?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("詳細を追加", text: $details, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.callout)
                .foregroundStyle(.secondary)
                .focused(detailsFocused)
                .lineLimit(1...5)
                .padding(.leading, 28)

            TaskRowDateSectionView(
                dueDate: dueDate,
                onSelectToday: onSelectToday,
                onSelectTomorrow: onSelectTomorrow,
                onUpdateDueDate: onUpdateDueDate
            )
            .padding(.leading, 28)

            TaskRowRecurrenceMenuView(recurrenceRule: $recurrenceRule)
                .padding(.leading, 28)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

private struct TaskRowDateSectionView: View {
    let dueDate: Date?
    let onSelectToday: () -> Void
    let onSelectTomorrow: () -> Void
    let onUpdateDueDate: (Date?) -> Void

    @State private var isShowingDatePicker = false
    @State private var pickerDate = Date()

    var body: some View {
        TaskRowDateControlsView(
            dueDate: dueDate,
            isShowingDatePicker: $isShowingDatePicker,
            pickerDate: $pickerDate,
            onSelectToday: onSelectToday,
            onSelectTomorrow: onSelectTomorrow,
            onUpdateDueDate: onUpdateDueDate
        )
        .onChange(of: dueDate) { _, newValue in
            pickerDate = newValue ?? Date()
        }
    }
}
