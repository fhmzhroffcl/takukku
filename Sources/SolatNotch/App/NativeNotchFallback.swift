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

        let label = NSTextField(labelWithString: "☾  SOL  ·  Mendapatkan waktu solat…")
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.alignment = .left
        label.frame = NSRect(x: 18, y: 8, width: 190, height: 20)
        visual.addSubview(label)
        panel.contentView = visual
        return panel
    }
}

private final class NotchRailView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        let rail = NSBezierPath(roundedRect: NSRect(x: 0, y: 1, width: bounds.width, height: 3), xRadius: 2, yRadius: 2)
        NSGradient(colors: [NSColor.systemBlue.withAlphaComponent(0.9), NSColor.systemPurple.withAlphaComponent(0.75), NSColor.systemPink.withAlphaComponent(0.8), NSColor.systemBlue.withAlphaComponent(0.9)])?.draw(in: rail, angle: 0)
    }
}
