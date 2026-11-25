import Foundation

/// Documents the existing Bark register query. Nothing in the app calls this.
enum BarkHTTPShape {
    static let registerPath = RegistrationPolicy.registerPath

    static func registerQuery(deviceToken: String, existingKey: String?) -> [String: String] {
        var query = [
            "devicetoken": deviceToken,
            "device_type": RegistrationPolicy.deviceType
        ]
        if let existingKey {
            let trimmed = existingKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                query["key"] = trimmed
            }
        }
        return query
    }
}
