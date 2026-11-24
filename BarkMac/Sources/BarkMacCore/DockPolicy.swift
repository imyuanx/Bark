import Foundation

enum DockPolicy {
    /// The Dock icon may be hidden only while a status item is installed.
    /// Otherwise the app would have no visible entry.
    static func hidesDock(preferenceHidden: Bool, statusItemInstalled: Bool) -> Bool {
        preferenceHidden && statusItemInstalled
    }
}
