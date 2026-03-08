import SwiftUI

struct TaskRowDateControlsView: View {
    let dueDate: Date?
    @Binding var isShowingDatePicker: Bool
    @Binding var pickerDate: Date
    let onSelectToday: () -> Void
    let onSelectTomorrow: () -> Void
    let onUpdateDueDate: (Date?) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onSelectToday) {
                Label("今日", systemImage: "sun.max")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button(action: onSelectTomorrow) {
                Label("明日", systemImage: "sunrise")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button {
                pickerDate = dueDate ?? Date()
                isShowingDatePicker.toggle()
            } label: {
                Label("日付", systemImage: "calendar")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .popover(isPresented: $isShowingDatePicker) {
                TaskDatePickerPopoverContent(
                    selectedDate: $pickerDate,
                    onDateChanged: onUpdateDueDate,
                    onClear: {
                        onUpdateDueDate(nil)
                        isShowingDatePicker = false
                    },
                    onClose: {
                        isShowingDatePicker = false
                    }
                )
            }

            if let dueDate {
                DateChipView(date: dueDate, onDateChanged: onUpdateDueDate)
            }
        }
    }
}
