import Foundation

enum NotificationPermissionCopy {
    static func permissionLine(statusName: String) -> String {
        "通知权限：\(statusName)。这只表示系统授权，服务器仍是未连接，APNs 仍是未验证。"
    }
}
