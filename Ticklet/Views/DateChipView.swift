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
            Text(formattedDate)
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(chipColor.opacity(0.15))
                .foregroundStyle(chipColor)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingPicker) {
            VStack(spacing: 8) {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .onChange(of: selectedDate) { _, newValue in
                        onDateChanged(newValue)
                    }

                HStack {
                    Button("削除") {
                        onDateChanged(nil)
                        showingPicker = false
                    }
                    .foregroundStyle(.red)

                    Spacer()

                    Button("閉じる") {
                        showingPicker = false
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .frame(width: 280)
        }
    }

    private var chipColor: Color {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let taskDay = cal.startOfDay(for: date)
        if taskDay < today { return .red }
        if cal.isDateInToday(date) { return .blue }
        return .secondary
    }

    private var formattedDate: String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "今日" }
        if cal.isDateInTomorrow(date) { return "明日" }
        if cal.isDateInYesterday(date) { return "昨日" }
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
