import Foundation

@MainActor
final class AppRuntime {
    static let shared = AppRuntime()
    let store: AppStore
    let notchCoordinator: NotchCoordinator
    let nativeNotch: NativeNotchPanelController
    private var started = false

    private init() {
        let store = AppStore()
        self.store = store
        self.notchCoordinator = NotchCoordinator(store: store)
        self.nativeNotch = NativeNotchPanelController(store: store)
    }
    func start() async {
        guard !started else { return }
        started = true
        store.start()
        nativeNotch.showOnAllDisplays()
    }
}
