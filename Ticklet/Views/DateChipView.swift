import SwiftUI

struct DateChipView: View {
    let date: Date
    let onDateChanged: (Date?) -> Void

    @State private var showingPicker = false
    @State private var selectedDate: Date

    init(date: Date, onDateChanged: @escaping (Date?) -> Void) {
        self.date = date
        self.onDateChanged = onDateChanged
        self._selectedDate = State(initialValue: date)
    }

    var body: some View {
        Button {
            showingPicker.toggle()
        } label: {
            Text(TaskDatePresentation.badgeText(for: date))
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(chipColor.opacity(0.15))
                .foregroundStyle(chipColor)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingPicker) {
            TaskDatePickerPopoverContent(
                selectedDate: $selectedDate,
                onDateChanged: onDateChanged,
                onClear: {
                    onDateChanged(nil)
                    showingPicker = false
                },
                onClose: {
                    showingPicker = false
                }
            )
        }
    }

    private var chipColor: Color {
        switch TaskDatePresentation.badgeStyle(for: date) {
        case .overdue:
            return .red
        case .today:
            return .blue
        case .normal:
            return .secondary
        }
    }
}

struct TaskDatePickerPopoverContent: View {
    @Binding var selectedDate: Date
    let onDateChanged: (Date?) -> Void
    let onClear: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .onChange(of: selectedDate) { _, newValue in
                    onDateChanged(newValue)
                }

            HStack {
                Button("削除", action: onClear)
                    .foregroundStyle(.red)

                Spacer()

                Button("閉じる", action: onClose)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 280)
    }
}
