import Foundation

struct RegistrationDecision: Equatable {
    enum Block: Equatable {
        case emptyAddress
        case officialServer
        case macosDeviceTypeNotAccepted
    }

    /// Always false in this version. A saved address is not a connection.
    let allowed: Bool
    let block: Block
    let deviceType: String

    var statusLine: String {
        switch block {
        case .emptyAddress:
            return "注册：未配置。注册已禁用，不会发送请求。"
        case .officialServer:
            return "注册：已禁用。不会向官方服务器发送注册。"
        case .macosDeviceTypeNotAccepted:
            return "地址：已保存。地址本身不能证明后端接受 device_type=macos。"
        }
    }
}

enum RegistrationPolicy {
    static let deviceType = "macos"
    static let registerPath = "/register"
    /// Launch never sends /register. A later explicit action still has to pass RegistrationGate.
    static let launchesRegistrationAutomatically = false
    /// Compared as a host string only. The app does not contact this host.
    static let officialHosts: Set<String> = ["api.day.app"]

    static func decision(forAddress address: String) -> RegistrationDecision {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let block: RegistrationDecision.Block
        if trimmed.isEmpty {
            block = .emptyAddress
        } else if let host = URL(string: trimmed)?.host?.lowercased(), officialHosts.contains(host) {
            block = .officialServer
        } else {
            block = .macosDeviceTypeNotAccepted
        }
        return RegistrationDecision(allowed: false, block: block, deviceType: deviceType)
    }
}
