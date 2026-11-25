import AppKit
import Combine
import UserNotifications

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel()
    private var statusMenu: StatusMenuController?
    private var windows: WindowPresenter?
    private var cancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = StatusMenuController(
            model: model,
            openMain: { [weak self] in self?.windows?.showMain() },
            openSettings: { [weak self] in self?.windows?.showSettings() }
        )
        statusMenu = menu
        windows = WindowPresenter(model: model, requestPermission: { [weak self] in
            self?.requestPermission()
        })
        menu.install()
        model.onPreferencesChanged = { [weak self] in
            self?.applyDockPolicy()
            self?.statusMenu?.rebuild()
        }
        cancellable = model.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.statusMenu?.rebuild()
            }
        }
        applyDockPolicy()
        refreshPermission()
        windows?.showMain()
    }

    func application(
        _ application: NSApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        model.noteAPNsToken(hex)
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        _ = error
        model.noteAPNsFailure()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        WindowPolicy.terminateAfterLastWindowClosed(stayResident: model.stayResident)
    }

    private func applyDockPolicy() {
        let installed = statusMenu?.isInstalled ?? false
        let wantsHidden = !model.showDockIcon
        let hide = DockPolicy.hidesDock(preferenceHidden: wantsHidden, statusItemInstalled: installed)
        if wantsHidden && !hide {
            model.revertDockIconVisible(note: "菜单栏图标不可用，已恢复 Dock 图标，避免应用没有入口。")
        }
        NSApp.setActivationPolicy(hide ? .accessory : .regular)
    }

    private func refreshPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let name = Self.permissionName(settings.authorizationStatus)
            DispatchQueue.main.async {
                self.model.permissionText = name
            }
        }
    }

    /// Local permission prompt only. This does not register with APNs or a Bark server.
    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            self.refreshPermission()
        }
    }

    private static func permissionName(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "未询问"
        case .denied:
            return "已拒绝"
        case .authorized:
            return "已允许"
        case .provisional:
            return "临时授权"
        case .ephemeral:
            return "临时会话"
        @unknown default:
            return "未知"
        }
    }
}
