import AppKit

final class OverlayWindow: NSWindow {
    init(screen: NSScreen, view: OverlayView) {
        super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        self.contentView = view
        self.backgroundColor = .clear
        self.isOpaque = false
        self.ignoresMouseEvents = true
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        self.hasShadow = false
        self.orderFrontRegardless()
    }
}
