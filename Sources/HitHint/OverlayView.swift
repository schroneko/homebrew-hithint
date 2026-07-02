import AppKit

final class OverlayView: NSView {
    var targets: [AXTarget] = [] {
        didSet { needsDisplay = true }
    }
    var query = "" {
        didSet { needsDisplay = true }
    }
    var activeTargetID: Int? {
        didSet { needsDisplay = true }
    }
    var mode: OverlayMode = .click {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()
        for target in targets {
            drawTarget(target)
        }
        drawQuery()
    }

    private func drawTarget(_ target: AXTarget) {
        guard let window else {
            return
        }
        let visible = query.isEmpty || target.label.hasPrefix(query)
        if !visible {
            return
        }
        let rect = localRect(for: target.frame, in: window.frame)
        if mode == .scroll {
            drawScrollFrame(rect, active: target.id == activeTargetID)
        }
        let point = CGPoint(x: rect.midX, y: max(10, rect.minY - 8))
        let fill: NSColor = target.label == query ? .systemGreen : .systemBlue
        drawPill(text: target.label, at: point, fill: fill)
    }

    private func drawScrollFrame(_ rect: CGRect, active: Bool) {
        let path = NSBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), xRadius: 8, yRadius: 8)
        (active ? NSColor.systemGreen : NSColor.systemBlue).withAlphaComponent(active ? 0.28 : 0.12).setFill()
        path.fill()
        (active ? NSColor.systemGreen : NSColor.systemBlue).setStroke()
        path.lineWidth = active ? 3 : 2
        path.stroke()
    }

    private func drawPill(text: String, at point: CGPoint, fill: NSColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 16, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let attributed = NSAttributedString(string: text.uppercased(), attributes: attributes)
        let size = attributed.size()
        let rect = CGRect(x: point.x - size.width / 2 - 7, y: point.y - 12, width: size.width + 14, height: 24)
        let path = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
        fill.setFill()
        path.fill()
        attributed.draw(at: CGPoint(x: rect.minX + 7, y: rect.minY + 3))
    }

    private func drawQuery() {
        if query.isEmpty {
            return
        }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        let text = NSAttributedString(string: query.uppercased(), attributes: attributes)
        let rect = CGRect(x: 20, y: 20, width: text.size().width + 24, height: 34)
        let path = NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8)
        NSColor.black.withAlphaComponent(0.72).setFill()
        path.fill()
        text.draw(at: CGPoint(x: rect.minX + 12, y: rect.minY + 7))
    }

    private func localRect(for screenRect: CGRect, in windowFrame: CGRect) -> CGRect {
        CGRect(
            x: screenRect.minX - windowFrame.minX,
            y: windowFrame.maxY - screenRect.maxY,
            width: screenRect.width,
            height: screenRect.height
        )
    }
}

enum OverlayMode {
    case click
    case scroll
}
