import Foundation

enum AppStorageKeys {
    static let serverAddress = "barkmac.serverAddress"
    static let stayResident = "barkmac.stayResident"
    static let showDockIcon = "barkmac.showDockIcon"
    static let userEnabledBackend = "barkmac.userEnabledBackendRegistration"
    static let backendMarkedCompatible = "barkmac.backendMarkedCompatible"
    static let userEnabledAPNs = "barkmac.userEnabledAPNs"
    static let signingAcknowledged = "barkmac.signingAcknowledged"

    /// Keys this app is allowed to write. Legacy iOS keys and the device token are absent.
    static let written: Set<String> = [
        serverAddress,
        stayResident,
        showDockIcon,
        userEnabledBackend,
        backendMarkedCompatible,
        userEnabledAPNs,
        signingAcknowledged
    ]
}
