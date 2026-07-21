import AppKit

@MainActor
final class NativeNotchFallback {
    static let shared = NativeNotchFallback()
    private var panels: [ObjectIdentifier: NSPanel] = [:]

    func show(on screens: [NSScreen] = NSScreen.screens) {
        for screen in screens {
            let id = ObjectIdentifier(screen)
            let frame = screen.frame
            let width: CGFloat = 520
            let height: CGFloat = 36
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

        let label = NSTextField(labelWithString: "☾  SOL  ·  Waktu solat sedang dimuat")
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.alignment = .center
        label.frame = NSRect(x: 28, y: 8, width: frame.width - 56, height: 20)
        visual.addSubview(label)
        panel.contentView = visual
        return panel
    }
}

private final class NotchRailView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        let left = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: bounds.width / 2 + 48, height: bounds.height), xRadius: 18, yRadius: 18)
        NSGradient(colors: [NSColor.systemBlue.withAlphaComponent(0.85), NSColor.systemPurple.withAlphaComponent(0.35), .clear])?.draw(in: left, angle: 0)
        let right = NSBezierPath(roundedRect: NSRect(x: bounds.width / 2 - 48, y: 0, width: bounds.width / 2 + 48, height: bounds.height), xRadius: 18, yRadius: 18)
        NSGradient(colors: [.clear, NSColor.systemPurple.withAlphaComponent(0.35), NSColor.systemBlue.withAlphaComponent(0.85)])?.draw(in: right, angle: 0)
        NSColor.black.setFill()
        NSBezierPath(roundedRect: NSRect(x: bounds.midX - 72, y: 0, width: 144, height: bounds.height), xRadius: 18, yRadius: 18).fill()
    }
}
