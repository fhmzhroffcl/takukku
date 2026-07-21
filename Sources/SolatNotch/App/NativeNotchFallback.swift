import AppKit

@MainActor
final class NativeNotchFallback {
    static let shared = NativeNotchFallback()
    private var panels: [ObjectIdentifier: NSPanel] = [:]

    func show(on screens: [NSScreen] = NSScreen.screens) {
        for screen in screens {
            let id = ObjectIdentifier(screen)
            let frame = screen.frame
            let width: CGFloat = 1000
            let height: CGFloat = 88
            let x = frame.midX - width / 2
            // Sit directly on the menu-bar edge so the black centre disappears
            // into the physical MacBook notch, like BoringNotch/NotchNook.
            let y = frame.maxY - height
            let panel = panels[id] ?? makePanel(frame: NSRect(x: x, y: y, width: width, height: height))
            panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
            panel.orderFrontRegardless()
            panels[id] = panel
        }
    }

    private func makePanel(frame: NSRect) -> NSPanel {
        let panel = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hasShadow = false

        let visual = NotchRailView(frame: NSRect(origin: .zero, size: frame.size))

        let label = NSTextField(labelWithString: "☾  SOL  ·  Mendapatkan waktu solat…")
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.alignment = .left
        label.frame = NSRect(x: 32, y: 48, width: 360, height: 22)
        visual.addSubview(label)
        panel.contentView = visual
        return panel
    }
}

private final class NotchRailView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        NSBezierPath(rect: bounds).fill()
        let wingWidth = bounds.midX - 90
        let left = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: wingWidth, height: bounds.height), xRadius: 18, yRadius: 18)
        NSGradient(colors: [NSColor.systemPink.withAlphaComponent(0.78), NSColor.systemBlue.withAlphaComponent(0.50), .clear])?.draw(in: left, angle: 0)
        let right = NSBezierPath(roundedRect: NSRect(x: bounds.midX + 90, y: 0, width: wingWidth, height: bounds.height), xRadius: 18, yRadius: 18)
        NSGradient(colors: [.clear, NSColor.systemBlue.withAlphaComponent(0.50), NSColor.systemPink.withAlphaComponent(0.78)])?.draw(in: right, angle: 0)
        let leftRail = NSBezierPath(roundedRect: NSRect(x: 0, y: 3, width: wingWidth, height: 3), xRadius: 2, yRadius: 2)
        NSGradient(colors: [NSColor.systemBlue, NSColor.systemPurple, NSColor.systemPink])?.draw(in: leftRail, angle: 0)
        let rightRail = NSBezierPath(roundedRect: NSRect(x: bounds.midX + 90, y: 3, width: wingWidth, height: 3), xRadius: 2, yRadius: 2)
        NSGradient(colors: [NSColor.systemPink, NSColor.systemPurple, NSColor.systemBlue])?.draw(in: rightRail, angle: 0)
    }
}
