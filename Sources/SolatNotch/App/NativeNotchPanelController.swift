import AppKit

@MainActor
final class NativeNotchPanelController {
    private let store: AppStore
    private var panels: [ObjectIdentifier: NSPanel] = [:]
    private var timer: Timer?

    init(store: AppStore) { self.store = store }

    func showOnAllDisplays() {
        for screen in NSScreen.screens {
            let id = ObjectIdentifier(screen)
            let panel = panels[id] ?? makePanel(for: screen)
            panel.orderFrontRegardless()
            panels[id] = panel
        }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        refresh()
    }

    private func makePanel(for screen: NSScreen) -> NSPanel {
        let width: CGFloat = min(1100, screen.frame.width - 80)
        let height: CGFloat = 92
        let frame = NSRect(x: screen.frame.midX - width / 2, y: screen.frame.maxY - height, width: width, height: height)
        let panel = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        let view = NativeNotchRailView(frame: NSRect(origin: .zero, size: frame.size))
        panel.contentView = view
        return panel
    }

    private func refresh() {
        for (id, panel) in panels {
            guard let view = panel.contentView as? NativeNotchRailView else { continue }
            view.update(title: title(), subtitle: subtitle())
            view.needsDisplay = true
            if let screen = NSScreen.screens.first(where: { ObjectIdentifier($0) == id }) {
                let width = panel.frame.width
                panel.setFrameOrigin(NSPoint(x: screen.frame.midX - width / 2, y: screen.frame.maxY - panel.frame.height))
            }
        }
    }

    private func title() -> String {
        switch store.state {
        case .needsZone: return "Pilih zon waktu solat"
        case .loading: return "Mendapatkan waktu solat…"
        case .failed: return "Waktu solat tidak dapat dikemas kini"
        case .loaded(_, let timeline): return "\(timeline.next.shortName)  \(timeline.next.malayName)"
        }
    }

    private func subtitle() -> String {
        guard case .loaded(_, let timeline) = store.state else { return store.selectedZone?.code ?? "Takukku" }
        let remaining = max(0, Int(timeline.nextDate.timeIntervalSinceNow))
        return String(format: "%02dj %02dm", remaining / 3600, (remaining % 3600) / 60)
    }
}

private final class NativeNotchRailView: NSView {
    private var titleText = "Solat Notch"
    private var subtitleText = "Mendapatkan waktu solat…"

    func update(title: String, subtitle: String) {
        titleText = title
        subtitleText = subtitle
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()
        let centerGap: CGFloat = 180
        let wingWidth = (bounds.width - centerGap) / 2
        let left = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: wingWidth, height: bounds.height), xRadius: 18, yRadius: 18)
        NSGradient(colors: [NSColor.systemPink.withAlphaComponent(0.82), NSColor.systemBlue.withAlphaComponent(0.55), .clear])?.draw(in: left, angle: 0)
        let right = NSBezierPath(roundedRect: NSRect(x: wingWidth + centerGap, y: 0, width: wingWidth, height: bounds.height), xRadius: 18, yRadius: 18)
        NSGradient(colors: [.clear, NSColor.systemBlue.withAlphaComponent(0.55), NSColor.systemPink.withAlphaComponent(0.82)])?.draw(in: right, angle: 0)
        let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 14, weight: .semibold)]
        (titleText as NSString).draw(at: NSPoint(x: 32, y: bounds.midY - 8), withAttributes: attrs)
        (subtitleText as NSString).draw(at: NSPoint(x: bounds.width - 230, y: bounds.midY - 8), withAttributes: attrs)
    }
}
