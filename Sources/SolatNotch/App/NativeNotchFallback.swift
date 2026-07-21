import AppKit

@MainActor
final class NativeNotchFallback {
    static let shared = NativeNotchFallback()
    private var panels: [ObjectIdentifier: NSPanel] = [:]

    func show(on screens: [NSScreen] = NSScreen.screens) {
        for screen in screens {
            let id = ObjectIdentifier(screen)
            let frame = screen.frame
            let width: CGFloat = 360
            let height: CGFloat = 42
            let x = frame.midX - width / 2
            // Leave the hardware/menu-bar notch clear; the panel belongs just
            // below it rather than underneath the display cut-out.
            let y = frame.maxY - 48 - height
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

        let visual = NSVisualEffectView(frame: NSRect(origin: .zero, size: frame.size))
        visual.material = .hudWindow
        visual.blendingMode = .behindWindow
        visual.state = .active
        visual.wantsLayer = true
        visual.layer?.cornerRadius = 21
        visual.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.94).cgColor

        let label = NSTextField(labelWithString: "☾  SOL  ·  Waktu solat sedang dimuat")
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.alignment = .center
        label.frame = NSRect(x: 12, y: 11, width: frame.width - 24, height: 20)
        visual.addSubview(label)
        panel.contentView = visual
        return panel
    }
}
