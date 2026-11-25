import Foundation

enum WindowPolicy {
    static let defaultStayResidentAfterLastWindowClosed = true
    static let defaultShowDockIcon = true

    static func terminateAfterLastWindowClosed(stayResident: Bool) -> Bool {
        !stayResident
    }
}
