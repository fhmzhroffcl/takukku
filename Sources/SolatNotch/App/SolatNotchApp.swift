import AppKit
import ServiceManagement
import SwiftUI
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        Task { await AppRuntime.shared.start() }
    }
}

@main
struct SolatNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store: AppStore
    @State private var coordinator: NotchCoordinator

    init() {
        let store = AppRuntime.shared.store
        let coordinator = AppRuntime.shared.notchCoordinator
        _store = StateObject(wrappedValue: store)
        _coordinator = State(initialValue: coordinator)
    }
    var body: some Scene {
        MenuBarExtra("Solat Notch", systemImage: "moon.stars.fill") {
            MenuBarContent(store: store, coordinator: coordinator)
        }
        WindowGroup("Tetapan Solat Notch", id: "settings") {
            SettingsView(store: store)
        }
        .defaultSize(width: 700, height: 620)
        .windowResizability(.contentMinSize)
    }
}

private struct MenuBarContent: View {
    @ObservedObject var store: AppStore
    let coordinator: NotchCoordinator
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    var body: some View {
        Group {
            switch store.state {
            case .needsZone: Text("Pilih zon waktu solat")
            case .loading: Text("Mendapatkan waktu solat…")
            case .failed(let reason): Text(reason); Button("Cuba Lagi") { store.refresh(force: true) }
            case .loaded(_, let timeline): Text("\(timeline.next.malayName) · \(TimeFormatter.string(timeline.nextDate))")
            }
            Button("Buka Solat Notch") { Task { await coordinator.expand() } }
            Button("Kecilkan") { Task { await coordinator.compactAll() } }
            Divider()
            Button("Tetapan…") { SettingsWindowPresenter.shared.show(store: store) }
            Toggle("Buka semasa log masuk", isOn: Binding(get: { launchAtLogin }, set: { enabled in launchAtLogin = enabled; setLogin(enabled) }))
            Divider(); Button("Keluar") { NSApp.terminate(nil) }
        }
    }
    private func setLogin(_ enabled: Bool) { do { if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() } } catch { launchAtLogin = !enabled } }
}
