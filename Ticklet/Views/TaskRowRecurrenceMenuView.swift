import SwiftUI

struct TaskRowRecurrenceMenuView: View {
    @Binding var recurrenceRule: RecurrenceRule?

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(RecurrenceRule.allCases, id: \.self) { rule in
                    Button(rule.displayName) {
                        recurrenceRule = rule
                    }
                }

                Divider()

                Button("なし") {
                    recurrenceRule = nil
                }
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "repeat")
                    Text(recurrenceRule?.displayName ?? "繰り返し")
                }
                .font(.caption)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }
}
