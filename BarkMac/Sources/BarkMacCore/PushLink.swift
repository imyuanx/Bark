import Foundation

enum PushLink {
    /// A copyable push URL exists only when this app has its own non-empty key
    /// and a locally valid base address. Building the string does not send it.
    static func copyableURL(baseAddress: String, independentKey: String?) -> String? {
        guard let key = independentKey?.trimmingCharacters(in: .whitespacesAndNewlines),
              !key.isEmpty
        else {
            return nil
        }
        guard case let .saved(saved) = AddressDraft.evaluate(baseAddress) else {
            return nil
        }
        let escaped = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
        return "\(saved)/\(escaped)"
    }
}
