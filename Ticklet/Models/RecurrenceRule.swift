import Foundation

enum RecurrenceRule: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    case yearly

    var displayName: String {
        switch self {
        case .daily: return "毎日"
        case .weekly: return "毎週"
        case .monthly: return "毎月"
        case .yearly: return "毎年"
        }
    }
}
