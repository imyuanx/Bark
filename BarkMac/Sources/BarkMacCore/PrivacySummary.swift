import Foundation

enum PrivacySummary {
    static let emptyMenuLine = "最近消息：无本地消息"

    /// Menu text keeps a short title only. Body and device key are discarded.
    static func menuLine(title: String, body: String, deviceKey: String?) -> String {
        _ = (body, deviceKey)
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let shown = trimmed.isEmpty ? "一条通知" : String(trimmed.prefix(40))
        return "最近消息：\(shown)"
    }
}
