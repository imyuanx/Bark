import Foundation

enum AppStorageKeys {
    static let serverAddress = "barkmac.serverAddress"
    static let stayResident = "barkmac.stayResident"
    static let showDockIcon = "barkmac.showDockIcon"

    /// Keys this app is allowed to write. Legacy iOS keys are absent on purpose.
    static let written: Set<String> = [
        serverAddress,
        stayResident,
        showDockIcon
    ]
}
