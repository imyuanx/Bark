import Combine
import Foundation

final class AppModel: ObservableObject {
    @Published var serverAddress: String
    @Published var addressDraft: String
    @Published var stayResident: Bool
    @Published var showDockIcon: Bool
    @Published var permissionText: String
    @Published var statusNote: String
    @Published var addressError: String?

    var onPreferencesChanged: (() -> Void)?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let address = defaults.string(forKey: AppStorageKeys.serverAddress) ?? ""
        serverAddress = address
        addressDraft = address
        stayResident = Self.storedBool(
            defaults,
            key: AppStorageKeys.stayResident,
            defaultValue: WindowPolicy.defaultStayResidentAfterLastWindowClosed
        )
        showDockIcon = Self.storedBool(
            defaults,
            key: AppStorageKeys.showDockIcon,
            defaultValue: WindowPolicy.defaultShowDockIcon
        )
        permissionText = "正在读取"
        statusNote = ""
        addressError = nil
    }

    /// Reads only this app's own key slot. Legacy iOS keys are never consulted.
    var independentKey: String? {
        guard let stored = defaults.string(forKey: KeyIsolation.independentKeyDefaultsKey) else {
            return nil
        }
        return KeyIsolation.independentKey(in: [
            KeyIsolation.independentKeyDefaultsKey: stored
        ])
    }

    var capability: CapabilityStatement {
        CapabilityStatement(serverAddress: serverAddress, notificationPermission: permissionText)
    }

    var registration: RegistrationDecision {
        RegistrationPolicy.decision(forAddress: serverAddress)
    }

    var staysRunningLabel: String {
        stayResident ? "关闭最后窗口：继续运行" : "关闭最后窗口：退出应用"
    }

    var dockLabel: String {
        showDockIcon ? "Dock 图标：显示" : "Dock 图标：隐藏，菜单栏图标仍在"
    }

    func saveDraft() {
        switch AddressDraft.evaluate(addressDraft) {
        case .cleared:
            serverAddress = ""
            addressDraft = ""
            defaults.set("", forKey: AppStorageKeys.serverAddress)
            addressError = nil
        case let .saved(value):
            serverAddress = value
            addressDraft = value
            defaults.set(value, forKey: AppStorageKeys.serverAddress)
            addressError = nil
        case let .rejected(message):
            addressError = message
        }
    }

    func setStayResident(_ value: Bool) {
        stayResident = value
        defaults.set(value, forKey: AppStorageKeys.stayResident)
        onPreferencesChanged?()
    }

    func setShowDock(_ value: Bool) {
        showDockIcon = value
        defaults.set(value, forKey: AppStorageKeys.showDockIcon)
        onPreferencesChanged?()
    }

    /// Restores the Dock icon without re-entering the preference callback.
    func revertDockIconVisible(note: String) {
        statusNote = note
        guard !showDockIcon else {
            return
        }
        showDockIcon = true
        defaults.set(true, forKey: AppStorageKeys.showDockIcon)
    }

    private static func storedBool(_ defaults: UserDefaults, key: String, defaultValue: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }
        return defaults.bool(forKey: key)
    }
}
