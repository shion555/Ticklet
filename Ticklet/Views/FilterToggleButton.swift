import SwiftUI

struct FilterToggleButton: View {
    let filterMode: FilterMode
    let onToggle: () -> Void

    var body: some View {
        Button {
            withAnimation {
                onToggle()
            }
        } label: {
            Image(systemName: filterMode == .starred ? "star.fill" : "star")
                .foregroundStyle(filterMode == .starred ? .yellow : .secondary)
        }
        .buttonStyle(.plain)
        .help(filterMode == .starred ? "すべてのタスク" : "スター付き")
    }
}
