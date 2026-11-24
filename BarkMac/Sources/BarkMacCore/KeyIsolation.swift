import Foundation

enum KeyIsolation {
    /// Slot for a key issued to this Mac app. This version never writes it.
    static let independentKeyDefaultsKey = "barkmac.independentDeviceKey"
    static let ignoredLegacyKeys = [
        "me.fin.bark.key",
        "key",
        "me.fin.bark.servers",
        "me.fin.bark.servers.current"
    ]

    static func independentKey(in defaults: [String: String]) -> String? {
        let raw = defaults[independentKeyDefaultsKey]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let raw, !raw.isEmpty else {
            return nil
        }
        return raw
    }
}
