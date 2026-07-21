import AppKit
import SwiftUI

@MainActor
final class SettingsWindowPresenter: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowPresenter()
    private var window: NSWindow?

    func show(store: AppStore) {
        NSApp.setActivationPolicy(.regular)
        if window == nil {
            let controller = NSHostingController(rootView: SettingsView(store: store))
            let created = NSWindow(contentViewController: controller)
            created.title = "Tetapan Solat Notch"
            created.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            created.setContentSize(NSSize(width: 700, height: 620))
            created.contentMinSize = NSSize(width: 680, height: 570)
            created.center()
            created.isReleasedWhenClosed = false
            created.delegate = self
            window = created
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
    }
}
