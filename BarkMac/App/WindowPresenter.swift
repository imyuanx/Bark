import AppKit
import SwiftUI

final class WindowPresenter {
    private let model: AppModel
    private let requestPermission: () -> Void
    private var mainWindow: NSWindow?
    private var settingsWindow: NSWindow?

    init(model: AppModel, requestPermission: @escaping () -> Void) {
        self.model = model
        self.requestPermission = requestPermission
    }

    func showMain() {
        let window = mainWindow ?? makeMain()
        mainWindow = window
        present(window)
    }

    func showSettings() {
        let window = settingsWindow ?? makeSettings()
        settingsWindow = window
        present(window)
    }

    private func makeMain() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Bark"
        window.contentView = NSHostingView(
            rootView: MainWindowView(model: model, requestPermission: requestPermission, openSettings: { [weak self] in
                self?.showSettings()
            })
        )
        window.isReleasedWhenClosed = false
        window.center()
        window.minSize = NSSize(width: 640, height: 480)
        window.setFrameAutosaveName("BarkMacMain")
        return window
    }

    private func makeSettings() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 460),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "设置"
        window.contentView = NSHostingView(rootView: SettingsWindowView(model: model))
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("BarkMacSettings")
        return window
    }

    private func present(_ window: NSWindow) {
        window.makeKeyAndOrderFront(nil)
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
