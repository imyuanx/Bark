import Foundation

enum APNsTokenPolicy {
    struct Input: Equatable {
        var userEnabled: Bool
        var signingAcknowledged: Bool
    }

    enum Outcome: Equatable {
        /// The default. The app must not call registerForRemoteNotifications.
        case notRequested
        /// The user asked, but this build is not acknowledged as signed for Push.
        case blockedUnsigned
        case allowed
    }

    static func evaluate(_ input: Input) -> Outcome {
        if !input.userEnabled {
            return .notRequested
        }
        if !input.signingAcknowledged {
            return .blockedUnsigned
        }
        return .allowed
    }
}
