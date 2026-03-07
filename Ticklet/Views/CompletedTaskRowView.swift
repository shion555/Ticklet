import SwiftUI

struct CompletedTaskRowView: View {
    @Bindable var task: TaskItem
    let onMarkIncomplete: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onMarkIncomplete) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            Text(task.title)
                .strikethrough()
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("削除", systemImage: "trash")
            }
        }
    }
}
