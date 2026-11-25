import Foundation

struct RegistrationRequest: Equatable {
    var url: URL
    var query: [String: String]
}

enum RegistrationGate {
    struct Input: Equatable {
        var serverAddress: String
        var userEnabled: Bool
        var backendMarkedCompatible: Bool
        /// Only the key stored for this Mac app. Never a legacy iOS key.
        var macKey: String?
        /// Present only after APNs actually returned a token.
        var deviceToken: String?
    }

    enum Outcome: Equatable {
        case blockedDisabled
        case blockedNoAddress
        case blockedOfficialServer
        case blockedBackendNotMarked
        case blockedNoDeviceToken
        case allowed(RegistrationRequest)
    }

    static func evaluate(_ input: Input) -> Outcome {
        if !input.userEnabled {
            return .blockedDisabled
        }
        let address = RegistrationPolicy.decision(forAddress: input.serverAddress)
        switch address.block {
        case .emptyAddress:
            return .blockedNoAddress
        case .officialServer:
            return .blockedOfficialServer
        case .macosDeviceTypeNotAccepted:
            break
        }
        if !input.backendMarkedCompatible {
            return .blockedBackendNotMarked
        }
        let token = input.deviceToken?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if token.isEmpty {
            return .blockedNoDeviceToken
        }
        guard case let .saved(saved) = AddressDraft.evaluate(input.serverAddress),
              let url = URL(string: saved + RegistrationPolicy.registerPath)
        else {
            return .blockedNoAddress
        }
        var query = [
            "devicetoken": token,
            "device_type": RegistrationPolicy.deviceType
        ]
        if let macKey = input.macKey?.trimmingCharacters(in: .whitespacesAndNewlines), !macKey.isEmpty {
            query["key"] = macKey
        }
        return .allowed(RegistrationRequest(url: url, query: query))
    }

    static func blockReason(_ outcome: Outcome) -> String {
        switch outcome {
        case .blockedDisabled:
            return "用户没有启用。"
        case .blockedNoAddress:
            return "服务器地址未配置。"
        case .blockedOfficialServer:
            return "不会向官方服务器注册。"
        case .blockedBackendNotMarked:
            return "这个地址还没有被标明为接受 device_type=macos 的隔离后端。"
        case .blockedNoDeviceToken:
            return "还没有本机 APNs token。"
        case .allowed:
            return ""
        }
    }
}

enum RegistrationAttempt {
    /// Calls the transport only for an allowed request. The transport is injected.
    static func perform(_ input: RegistrationGate.Input, transport: (RegistrationRequest) -> Void) -> RegistrationGate.Outcome {
        let outcome = RegistrationGate.evaluate(input)
        if case let .allowed(request) = outcome {
            transport(request)
        }
        return outcome
    }
}

enum RegistrationResponse {
    static func macKey(from data: Data, legacyValues: [String]) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        let nested = object["data"] as? [String: Any]
        let raw = (nested?["key"] as? String) ?? (object["key"] as? String) ?? ""
        return MacKeyStore.keyFromRegistration(raw, legacyValues: legacyValues)
    }
}

enum MacKeyStore {
    /// Accepts a key returned by an isolated backend. Refuses a value that matches a legacy key.
    static func keyFromRegistration(_ responseKey: String, legacyValues: [String]) -> String? {
        let trimmed = responseKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        if legacyValues.contains(where: { $0 == trimmed }) {
            return nil
        }
        return trimmed
    }
}
