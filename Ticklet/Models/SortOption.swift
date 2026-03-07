import Foundation

enum SortOption: String, Codable, CaseIterable {
    case manual = "指定した順序"
    case date = "日付"
    case dueDate = "期限"
    case title = "タイトル"

    var displayName: String { rawValue }
}

enum FilterMode: String, CaseIterable {
    case all = "すべてのタスク"
    case starred = "スター付き"
}
