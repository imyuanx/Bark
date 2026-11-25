import AppKit

/// The only place that may call registerForRemoteNotifications.
enum APNsTokenClient {
    static func requestIfAllowed(userEnabled: Bool, signingAcknowledged: Bool) -> APNsTokenPolicy.Outcome {
        let outcome = APNsTokenPolicy.evaluate(
            APNsTokenPolicy.Input(userEnabled: userEnabled, signingAcknowledged: signingAcknowledged)
        )
        if case .allowed = outcome {
            NSApplication.shared.registerForRemoteNotifications()
        }
        return outcome
    }
}
