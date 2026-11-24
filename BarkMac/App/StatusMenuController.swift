import AppKit

/// There is no background archive in this version, so the menu has nothing to summarize.
enum LocalHistory {
    static func latest() -> (title: String, body: String)? {
        nil
    }
}

final class StatusMenuController: NSObject, NSMenuDelegate {
    private let model: AppModel
    private let openMain: () -> Void
    private let openSettings: () -> Void
    private var statusItem: NSStatusItem?

    var isInstalled: Bool {
        statusItem?.button != nil
    }

    init(model: AppModel, openMain: @escaping () -> Void, openSettings: @escaping () -> Void) {
        self.model = model
        self.openMain = openMain
        self.openSettings = openSettings
    }

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "bell.fill", accessibilityDescription: "Bark")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "Bark"
            button.setAccessibilityLabel("Bark 菜单")
        }
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item
        rebuild()
    }

    func rebuild() {
        guard let menu = statusItem?.menu else {
            return
        }
        menu.removeAllItems()
        addDisabled("Bark Mac")
        menu.addItem(.separator())
        addDisabled(NotificationPermissionCopy.permissionLine(statusName: model.permissionText))
        addDisabled(model.capability.serverLine)
        addDisabled(model.registration.statusLine)
        addDisabled(CapabilityStatement.apnsLine)
        if let latest = LocalHistory.latest() {
            addDisabled(PrivacySummary.menuLine(
                title: latest.title,
                body: latest.body,
                deviceKey: model.independentKey
            ))
        } else {
            addDisabled(PrivacySummary.emptyMenuLine)
        }
        if !model.statusNote.isEmpty {
            addDisabled(model.statusNote)
        }
        menu.addItem(.separator())
        addAction("打开主窗口", action: #selector(openMainWindow), key: "o", enabled: true)
        addAction("设置…", action: #selector(openSettingsWindow), key: ",", enabled: true)
        let url = PushLink.copyableURL(
            baseAddress: model.serverAddress,
            independentKey: model.independentKey
        )
        addAction(
            url == nil ? "复制推送 URL（尚无独立 key）" : "复制推送 URL",
            action: #selector(copyPushURL),
            key: "",
            enabled: url != nil
        )
        menu.addItem(.separator())
        addAction("退出 Bark Mac", action: #selector(quit), key: "q", enabled: true)
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuild()
    }

    private func addDisabled(_ title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        statusItem?.menu?.addItem(item)
    }

    private func addAction(_ title: String, action: Selector, key: String, enabled: Bool) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        item.isEnabled = enabled
        statusItem?.menu?.addItem(item)
    }

    @objc private func openMainWindow() {
        openMain()
    }

    @objc private func openSettingsWindow() {
        openSettings()
    }

    @objc private func copyPushURL() {
        guard let url = PushLink.copyableURL(
            baseAddress: model.serverAddress,
            independentKey: model.independentKey
        ) else {
            return
        }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url, forType: .string)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
