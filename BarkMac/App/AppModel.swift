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
    @Published var userEnabledBackend: Bool
    @Published var backendMarkedCompatible: Bool
    @Published var userEnabledAPNs: Bool
    @Published var signingAcknowledged: Bool
    @Published var apnsStage: APNsTokenStage
    @Published var backendStage: BackendStage
    private var deviceToken: String?

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
        userEnabledBackend = Self.storedBool(
            defaults, key: AppStorageKeys.userEnabledBackend, defaultValue: false
        )
        backendMarkedCompatible = Self.storedBool(
            defaults, key: AppStorageKeys.backendMarkedCompatible, defaultValue: false
        )
        userEnabledAPNs = Self.storedBool(
            defaults, key: AppStorageKeys.userEnabledAPNs, defaultValue: false
        )
        signingAcknowledged = Self.storedBool(
            defaults, key: AppStorageKeys.signingAcknowledged, defaultValue: false
        )
        apnsStage = .notRequested
        backendStage = .notRequested
        deviceToken = nil
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

    var stages: DeliveryStages {
        DeliveryStages(
            permissionName: permissionText,
            apns: apnsStage,
            backend: backendStage,
            delivery: .notObserved
        )
    }

    var registrationInput: RegistrationGate.Input {
        RegistrationGate.Input(
            serverAddress: serverAddress,
            userEnabled: userEnabledBackend,
            backendMarkedCompatible: backendMarkedCompatible,
            macKey: independentKey,
            deviceToken: deviceToken
        )
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
    func setUserEnabledBackend(_ value: Bool) {
        userEnabledBackend = value
        defaults.set(value, forKey: AppStorageKeys.userEnabledBackend)
        if !value, case .blocked = backendStage {
            backendStage = .notRequested
        }
    }

    func setBackendMarkedCompatible(_ value: Bool) {
        backendMarkedCompatible = value
        defaults.set(value, forKey: AppStorageKeys.backendMarkedCompatible)
    }

    func setUserEnabledAPNs(_ value: Bool) {
        userEnabledAPNs = value
        defaults.set(value, forKey: AppStorageKeys.userEnabledAPNs)
        if !value {
            apnsStage = .notRequested
        }
    }

    func setSigningAcknowledged(_ value: Bool) {
        signingAcknowledged = value
        defaults.set(value, forKey: AppStorageKeys.signingAcknowledged)
    }

    /// Explicit only. Launch does not call this.
    func requestAPNsToken() {
        let outcome = APNsTokenClient.requestIfAllowed(
            userEnabled: userEnabledAPNs,
            signingAcknowledged: signingAcknowledged
        )
        switch outcome {
        case .notRequested:
            apnsStage = .notRequested
        case .blockedUnsigned:
            apnsStage = .blockedUnsigned
        case .allowed:
            apnsStage = .requested
        }
    }

    func noteAPNsToken(_ token: String) {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        deviceToken = trimmed
        apnsStage = .receivedHidden
    }

    func noteAPNsFailure() {
        deviceToken = nil
        apnsStage = .failed("系统没有返回 token。后端注册没有发送。")
    }

    /// Explicit only. Sends only when RegistrationGate allows it.
    func runBackendRegistration() {
        let outcome = RegistrationAttempt.perform(registrationInput) { request in
            self.backendStage = .waiting
            LiveBarkRegisterTransport.send(request) { result in
                DispatchQueue.main.async {
                    self.finishRegistration(result)
                }
            }
        }
        if case .allowed = outcome {
            return
        }
        backendStage = .blocked(RegistrationGate.blockReason(outcome))
    }

    private func finishRegistration(_ result: Result<Data, Error>) {
        switch result {
        case let .success(data):
            guard let key = RegistrationResponse.macKey(from: data, legacyValues: []) else {
                backendStage = .failed("响应里没有可用的新 Mac key。没有写入任何 key。")
                return
            }
            defaults.set(key, forKey: KeyIsolation.independentKeyDefaultsKey)
            backendStage = .accepted
        case .failure:
            backendStage = .failed("网络请求失败。不表示服务端已投递。")
        }
    }

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
