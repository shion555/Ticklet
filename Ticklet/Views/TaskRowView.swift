import SwiftUI
import SwiftData

struct TaskRowView: View {
    @Bindable var task: TaskItem
    @Environment(\.modelContext) private var modelContext
    let isExpanded: Bool
    let onTap: () -> Void
    let onComplete: () -> Void

    @State private var isHovering = false
    @FocusState private var titleFocused: Bool
    @FocusState private var detailsFocused: Bool
    @State private var showDatePicker = false
    @State private var pickerDate = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            collapsedRow
            if isExpanded {
                expandedContent
            }

            // Subtasks
            let subtasks = (task.subtasks).sorted { $0.sortOrder < $1.sortOrder }
            ForEach(subtasks) { sub in
                SubtaskRowView(subtask: sub)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .contextMenu { contextMenuItems }
    }

    // MARK: - Collapsed Row
    private var collapsedRow: some View {
        HStack(spacing: 6) {
            Button {
                onComplete()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .gray : .blue)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            if isExpanded {
                TextField("タイトル", text: $task.title)
                    .textFieldStyle(.plain)
                    .focused($titleFocused)
            } else {
                Button { onTap() } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .lineLimit(1)
                            .foregroundStyle(.primary)

                        if let due = task.dueDate {
                            DateChipView(date: due) { newDate in
                                task.dueDate = newDate
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)

            if isHovering || task.isStarred {
                Button {
                    withAnimation { task.isStarred.toggle() }
                } label: {
                    Image(systemName: task.isStarred ? "star.fill" : "star")
                        .foregroundStyle(task.isStarred ? .yellow : .secondary)
                        .font(.callout)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Expanded Content
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("詳細を追加", text: $task.details, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.callout)
                .foregroundStyle(.secondary)
                .focused($detailsFocused)
                .lineLimit(1...5)
                .padding(.leading, 28)

            // Date buttons row
            HStack(spacing: 8) {
                Button {
                    task.dueDate = Calendar.current.startOfDay(for: Date())
                } label: {
                    Label("今日", systemImage: "sun.max")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    task.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))
                } label: {
                    Label("明日", systemImage: "sunrise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    pickerDate = task.dueDate ?? Date()
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
                            .onChange(of: pickerDate) { _, newVal in
                                task.dueDate = newVal
                            }

                        HStack {
                            Button("削除") {
                                task.dueDate = nil
                                showDatePicker = false
                            }
                            .foregroundStyle(.red)
                            Spacer()
                            Button("閉じる") { showDatePicker = false }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .frame(width: 280)
                }

                if let due = task.dueDate {
                    DateChipView(date: due) { newDate in
                        task.dueDate = newDate
                    }
                }
            }
            .padding(.leading, 28)

            // Recurrence
            HStack(spacing: 8) {
                Menu {
                    ForEach(RecurrenceRule.allCases, id: \.self) { rule in
                        Button(rule.displayName) {
                            task.recurrenceRule = rule
                        }
                    }
                    Divider()
                    Button("なし") {
                        task.recurrenceRule = nil
                    }
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "repeat")
                        Text(task.recurrenceRule?.displayName ?? "繰り返し")
                    }
                    .font(.caption)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.leading, 28)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Context Menu
    @ViewBuilder
    private var contextMenuItems: some View {
        if task.isTopLevel {
            Button {
                addSubtask()
            } label: {
                Label("サブタスクを追加", systemImage: "text.line.first.and.arrowtriangle.forward")
            }
        }

        Button {
            withAnimation { task.isStarred.toggle() }
        } label: {
            Label(task.isStarred ? "スターを外す" : "スターを付ける", systemImage: task.isStarred ? "star.slash" : "star")
        }

        Divider()

        Button(role: .destructive) {
            withAnimation { modelContext.delete(task) }
        } label: {
            Label("削除", systemImage: "trash")
        }
    }

    private func addSubtask() {
        let sub = TaskItem(
            title: "",
            sortOrder: task.subtasks.count,
            list: task.list,
            parentID: task.id
        )
        task.subtasks.append(sub)
        modelContext.insert(sub)
    }
}
