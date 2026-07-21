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
        await notchCoordinator.presentCompactOnAllDisplays()
        if store.selectedZone == nil { SettingsWindowPresenter.shared.show(store: store) }
    }
}
