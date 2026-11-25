import Foundation

/// Four separate facts. None of them is implied by another.
struct DeliveryStages: Equatable {
    var permissionName: String
    var apns: APNsTokenStage
    var backend: BackendStage
    var delivery: ServerDeliveryStage

    var permissionLine: String {
        "系统通知权限：\(permissionName)。只表示本机授权。"
    }

    var apnsLine: String {
        switch apns {
        case .notRequested:
            return "APNs token：未请求。没有调用 registerForRemoteNotifications。"
        case .requested:
            return "APNs token：已向 APNs 请求，结果尚未返回。token 不会显示。"
        case .blockedUnsigned:
            return "APNs token：未请求。签名确认未打开，没有 Push entitlement。"
        case .receivedHidden:
            return "APNs token：已收到。内容不显示。后端注册仍要单独进行。"
        case let .failed(message):
            return "APNs token：请求失败。\(message)"
        }
    }

    var backendLine: String {
        switch backend {
        case .notRequested:
            return "后端注册：未请求。没有发送 /register。"
        case let .blocked(message):
            return "后端注册：未发送。\(message)"
        case .waiting:
            return "后端注册：已发送 /register，结果尚未返回。这不是投递成功。"
        case .accepted:
            return "后端注册：这个隔离后端已返回新的 Mac key。不表示服务端已经投递。"
        case let .failed(message):
            return "后端注册：请求失败。\(message)"
        }
    }

    var deliveryLine: String {
        switch delivery {
        case .notObserved:
            return "服务端投递：未观察。本应用不能把它标成已送达。"
        }
    }

    var claimsConnected: Bool { false }
    var claimsDelivered: Bool { false }
}

enum APNsTokenStage: Equatable {
    case notRequested
    case requested
    case blockedUnsigned
    case receivedHidden
    case failed(String)
}

enum BackendStage: Equatable {
    case notRequested
    case blocked(String)
    case waiting
    case accepted
    case failed(String)
}

enum ServerDeliveryStage: Equatable {
    case notObserved
}
