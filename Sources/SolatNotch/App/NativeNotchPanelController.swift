import AppKit

@MainActor
final class NativeNotchPanelController {
    private let store: AppStore
    private var panels: [ObjectIdentifier: NSPanel] = [:]
    private var expanded: Set<ObjectIdentifier> = []
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
        let metrics = metrics(for: screen)
        let width = metrics.width
        let height: CGFloat = 42
        let frame = NSRect(x: metrics.originX, y: screen.frame.maxY - height, width: width, height: height)
        let panel = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.acceptsMouseMovedEvents = true
        panel.isMovableByWindowBackground = false
        let view = NativeNotchRailView(frame: NSRect(origin: .zero, size: frame.size), notchWidth: metrics.notchWidth)
        view.onToggle = { [weak self, weak panel] in
            guard let self, let panel else { return }
            self.toggle(panel: panel, screen: screen)
        }
        panel.contentView = view
        return panel
    }

    private func refresh() {
        for (id, panel) in panels {
            guard let view = panel.contentView as? NativeNotchRailView else { continue }
            view.update(title: title(), subtitle: subtitle(), schedule: schedule(), weather: weather())
            view.needsDisplay = true
            if let screen = NSScreen.screens.first(where: { ObjectIdentifier($0) == id }) {
                let metrics = metrics(for: screen)
                panel.setFrame(NSRect(x: metrics.originX, y: screen.frame.maxY - panel.frame.height, width: metrics.width, height: panel.frame.height), display: false)
            }
        }
    }

    private func toggle(panel: NSPanel, screen: NSScreen) {
        let id = ObjectIdentifier(screen)
        if expanded.contains(id) { expanded.remove(id) } else { expanded.insert(id) }
        let height: CGFloat = expanded.contains(id) ? 320 : 42
        let metrics = metrics(for: screen)
        panel.setFrame(NSRect(x: metrics.originX, y: screen.frame.maxY - height, width: metrics.width, height: height), display: true, animate: true)
        (panel.contentView as? NativeNotchRailView)?.isExpanded = expanded.contains(id)
        panel.contentView?.needsDisplay = true
    }

    private func metrics(for screen: NSScreen) -> (originX: CGFloat, width: CGFloat, notchWidth: CGFloat) {
        let left = screen.auxiliaryTopLeftArea?.maxX ?? (screen.frame.midX - 110)
        let right = screen.auxiliaryTopRightArea?.minX ?? (screen.frame.midX + 110)
        let notchWidth = max(180, right - left)
        let wing: CGFloat = 120
        let width = min(screen.frame.width - 24, notchWidth + wing * 2)
        let originX = max(screen.frame.minX + 12, min(left - wing, screen.frame.maxX - width - 12))
        return (originX, width, notchWidth)
    }

    private func title() -> String {
        switch store.state {
        case .needsZone: return "Pilih zon"
        case .loading: return "Muat…"
        case .failed: return "Ralat"
        case .loaded(_, let timeline): return "\(timeline.next.shortName)  \(timeline.next.malayName)"
        }
    }

    private func subtitle() -> String {
        guard case .loaded(_, let timeline) = store.state else { return store.selectedZone?.code ?? "Takukku" }
        let remaining = max(0, Int(timeline.nextDate.timeIntervalSinceNow))
        return String(format: "%02dj %02dm", remaining / 3600, (remaining % 3600) / 60)
    }

    private func schedule() -> DailyPrayerTimes? {
        if case .loaded(let schedule, _) = store.state { return schedule }
        return store.lastSchedule
    }

    private func weather() -> String? {
        guard let weather = store.weather else { return nil }
        return "\(Int(weather.temperature.rounded()))°"
    }
}

private final class NativeNotchRailView: NSView {
    private var titleText = "Solat Notch"
    private var subtitleText = "Mendapatkan waktu solat…"
    private var schedule: DailyPrayerTimes?
    private var weatherText: String?
    private let notchWidth: CGFloat
    var isExpanded = false
    var onToggle: (() -> Void)?

    init(frame frameRect: NSRect, notchWidth: CGFloat) {
        self.notchWidth = notchWidth
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) { return nil }

    func update(title: String, subtitle: String, schedule: DailyPrayerTimes?, weather: String?) {
        titleText = title
        subtitleText = subtitle
        self.schedule = schedule
        weatherText = weather
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()
        if isExpanded { drawExpanded(); return }
        let centerGap = notchWidth
        let wingWidth = (bounds.width - centerGap) / 2
        let left = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: wingWidth, height: bounds.height), xRadius: 18, yRadius: 18)
        NSGradient(colors: [NSColor.systemPink.withAlphaComponent(0.82), NSColor.systemBlue.withAlphaComponent(0.55), .clear])?.draw(in: left, angle: 0)
        let right = NSBezierPath(roundedRect: NSRect(x: wingWidth + centerGap, y: 0, width: wingWidth, height: bounds.height), xRadius: 18, yRadius: 18)
        NSGradient(colors: [.clear, NSColor.systemBlue.withAlphaComponent(0.55), NSColor.systemPink.withAlphaComponent(0.82)])?.draw(in: right, angle: 0)
        let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 12, weight: .semibold)]
        let centre = bounds.midX
        (titleText as NSString).draw(at: NSPoint(x: centre - notchWidth / 2 + 16, y: bounds.midY - 7), withAttributes: attrs)
        (subtitleText as NSString).draw(at: NSPoint(x: centre + notchWidth / 2 - 58, y: bounds.midY - 7), withAttributes: attrs)
    }

    override func mouseDown(with event: NSEvent) { onToggle?() }

    private func drawExpanded() {
        let gradient = NSGradient(colors: [NSColor.black, NSColor(calibratedRed: 0.02, green: 0.12, blue: 0.35, alpha: 1), NSColor(calibratedRed: 0.02, green: 0.42, blue: 0.85, alpha: 1)])
        gradient?.draw(in: NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height), angle: 90)
        let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 16, weight: .semibold)]
        (titleText as NSString).draw(at: NSPoint(x: 34, y: bounds.height - 58), withAttributes: attrs)
        if let weatherText { (weatherText as NSString).draw(at: NSPoint(x: bounds.width - 100, y: bounds.height - 58), withAttributes: attrs) }
        let arc = NSBezierPath()
        arc.move(to: NSPoint(x: 42, y: 105))
        arc.curve(to: NSPoint(x: bounds.width - 42, y: 105), controlPoint1: NSPoint(x: bounds.width * 0.25, y: 230), controlPoint2: NSPoint(x: bounds.width * 0.75, y: 230))
        NSColor.systemBlue.withAlphaComponent(0.75).setStroke(); arc.lineWidth = 1.5; arc.stroke()
        guard let schedule else { return }
        let prayers = Prayer.allCases
        let step = (bounds.width - 100) / CGFloat(prayers.count - 1)
        let small: [NSAttributedString.Key: Any] = [.foregroundColor: NSColor.white, .font: NSFont.systemFont(ofSize: 12, weight: .medium)]
        for (index, prayer) in prayers.enumerated() {
            let x = 50 + CGFloat(index) * step
            let name = prayer.shortName as NSString
            name.draw(at: NSPoint(x: x - 15, y: 65), withAttributes: small)
            if let date = schedule[prayer] { (TimeFormatter.string(date) as NSString).draw(at: NSPoint(x: x - 28, y: 44), withAttributes: small) }
        }
        let source = "JAKIM melalui Waktu Solat API · \(schedule.zoneCode)" as NSString
        source.draw(at: NSPoint(x: 34, y: 18), withAttributes: [.foregroundColor: NSColor.white.withAlphaComponent(0.65), .font: NSFont.systemFont(ofSize: 11)])
    }
}
