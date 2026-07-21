import Foundation

@MainActor
final class AppRuntime {
    static let shared = AppRuntime()
    let store: AppStore
    let notchCoordinator: NotchCoordinator
    private var started = false

    private init() {
        let store = AppStore()
        self.store = store
        self.notchCoordinator = NotchCoordinator(store: store)
    }
    func start() async {
        guard !started else { return }
        started = true
        store.start()
        NativeNotchFallback.shared.show()
        // Keep startup reliable on macOS 26 while the DynamicNotchKit panel
        // is being replaced with the native panel path. The menu-bar app and
        // settings remain available immediately; the notch is created only
        // after an explicit user action.
        // Do not auto-open the settings window during startup. SwiftUI's
        // segmented controls can trigger an AppKit layout crash on macOS 26
        // before the menu-bar scene has finished attaching. The user can open
        // settings from the menu bar once the app is running.
    }
}
