import AppKit
import DynamicNotchKit
import SwiftUI

@MainActor
final class NotchCoordinator {
    typealias Notch = DynamicNotch<ExpandedNotchView, CompactPrayerLeading, CompactPrayerTrailing>
    private var notches: [ObjectIdentifier: Notch] = [:]
    private var hoverCollapseTask: Task<Void, Never>?
    private let store: AppStore
    init(store: AppStore) { self.store = store }

    func presentCompactOnAllDisplays() async {
        for screen in NSScreen.screens {
            let id = ObjectIdentifier(screen)
            let notch = notches[id] ?? makeNotch()
            notches[id] = notch
            await notch.compact(on: screen)
        }
        notches = notches.filter { key, _ in NSScreen.screens.contains { ObjectIdentifier($0) == key } }
    }
    func expand(on screen: NSScreen? = NSScreen.main) async { hoverCollapseTask?.cancel(); guard let screen else { return }; let id = ObjectIdentifier(screen); let notch = notches[id] ?? makeNotch(); notches[id] = notch; await notch.expand(on: screen) }
    func compactAll() async { hoverCollapseTask?.cancel(); for (id, notch) in notches { if let screen = NSScreen.screens.first(where: { ObjectIdentifier($0) == id }) { await notch.compact(on: screen) } } }
    func hoverChanged(_ hovering: Bool) {
        let mode = UserDefaults.standard.string(forKey: "expansionMode") ?? ExpansionMode.both.rawValue
        guard mode == ExpansionMode.hover.rawValue || mode == ExpansionMode.both.rawValue else { return }
        hoverCollapseTask?.cancel()
        if hovering { Task { await expand() } }
        else { hoverCollapseTask = Task { try? await Task.sleep(for: .milliseconds(220)); guard !Task.isCancelled else { return }; await compactAll() } }
    }
    private func makeNotch() -> Notch {
        let notch = Notch(
            hoverBehavior: [.keepVisible, .increaseShadow],
            style: .auto,
            expanded: { ExpandedNotchView(store: self.store, onCollapse: { [weak self] in Task { await self?.compactAll() } }, onHover: { [weak self] in self?.hoverChanged($0) }) },
            compactLeading: { CompactPrayerLeading(store: self.store, onExpand: { [weak self] in Task { await self?.expand() } }, onHover: { [weak self] in self?.hoverChanged($0) }) },
            compactTrailing: { CompactPrayerTrailing(store: self.store, onExpand: { [weak self] in Task { await self?.expand() } }, onHover: { [weak self] in self?.hoverChanged($0) }) }
        )
        notch.transitionConfiguration = .init(openingAnimation: .spring(response: 0.30, dampingFraction: 0.92), closingAnimation: .easeOut(duration: 0.20), conversionAnimation: .spring(response: 0.32, dampingFraction: 0.94), skipIntermediateHides: true)
        return notch
    }
}
