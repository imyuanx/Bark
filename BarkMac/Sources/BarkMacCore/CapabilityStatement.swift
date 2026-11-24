import Foundation

struct CapabilityStatement: Equatable {
    var serverAddress: String
    var notificationPermission: String

    var connected: Bool { false }
    var verified: Bool { false }
    var apnsReady: Bool { false }

    static let apnsLine = "推送：未向 APNs 注册，未验证。通知权限不等于推送可达。"

    var serverLine: String {
        let trimmed = serverAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "服务器：未配置"
        }
        return "服务器：已保存地址，未注册，未连接，未验证"
    }
}
