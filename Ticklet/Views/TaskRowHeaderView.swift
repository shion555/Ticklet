import SwiftUI

struct TaskRowHeaderView: View {
    @Binding var title: String
    let dueDate: Date?
    let isExpanded: Bool
    let isCompleted: Bool
    let isStarred: Bool
    let isHovering: Bool
    let titleFocused: FocusState<Bool>.Binding
    let onTap: () -> Void
    let onComplete: () -> Void
    let onToggleStar: () -> Void
    let onUpdateDueDate: (Date?) -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onComplete) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCompleted ? .gray : .blue)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            if isExpanded {
                TextField("タイトル", text: $title)
                    .textFieldStyle(.plain)
                    .focused(titleFocused)
            } else {
                Button(action: onTap) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .lineLimit(1)
                            .foregroundStyle(.primary)

                        if let dueDate {
                            DateChipView(date: dueDate, onDateChanged: onUpdateDueDate)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)

            if isHovering || isStarred {
                Button(action: onToggleStar) {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .foregroundStyle(isStarred ? .yellow : .secondary)
                        .font(.callout)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
