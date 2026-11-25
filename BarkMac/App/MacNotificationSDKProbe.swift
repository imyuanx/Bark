import UserNotifications

/// Compiled into the native macOS app target. This is not an installed
/// Notification Service Extension, and nothing here observes a system launch.
enum MacNotificationSDKProbe {
    static let extensionPointIdentifier = "com.apple.usernotifications.service"

    static var summary: String {
        if #available(macOS 10.14, *) {
            _ = MacNotificationServiceCompileProbe.self
            return "通知服务扩展类在这个 macOS SDK 中可编译。本构建没有安装 appex，也没有观察系统是否调用它。"
        }
        return "这个部署版本看不到 UNNotificationServiceExtension。"
    }
}

@available(macOS 10.14, *)
final class MacNotificationServiceCompileProbe: UNNotificationServiceExtension {
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        contentHandler(request.content)
    }

    override func serviceExtensionTimeWillExpire() {}
}
