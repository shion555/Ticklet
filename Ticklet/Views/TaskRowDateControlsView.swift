import SwiftUI

struct TaskRowDateControlsView: View {
    let dueDate: Date?
    @Binding var showDatePicker: Bool
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
                showDatePicker.toggle()
            } label: {
                Label("日付", systemImage: "calendar")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .popover(isPresented: $showDatePicker) {
                VStack {
                    DatePicker("", selection: $pickerDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .onChange(of: pickerDate) { _, newValue in
                            onUpdateDueDate(newValue)
                        }

                    HStack {
                        Button("削除") {
                            onUpdateDueDate(nil)
                            showDatePicker = false
                        }
                        .foregroundStyle(.red)

                        Spacer()

                        Button("閉じる") {
                            showDatePicker = false
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
                .frame(width: 280)
            }

            if let dueDate {
                DateChipView(date: dueDate, onDateChanged: onUpdateDueDate)
            }
        }
    }
}
