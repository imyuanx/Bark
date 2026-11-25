import Foundation

enum AddressDraft {
    enum Result: Equatable {
        case cleared
        case saved(String)
        case rejected(String)
    }

    /// Validates a server address for local storage. This does not open a connection.
    static func evaluate(_ raw: String) -> Result {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .cleared
        }
        guard let components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host,
              !host.isEmpty
        else {
            return .rejected("需要包含主机名的 http 或 https 地址。这里只做本地保存，不会发起网络请求。")
        }
        var normalized = trimmed
        while normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        return .saved(normalized)
    }
}
