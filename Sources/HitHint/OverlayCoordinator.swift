import AppKit

final class OverlayCoordinator {
    private var windows: [OverlayWindow] = []
    private var views: [OverlayView] = []
    private let keyboard = KeyboardEventTap.shared

    func show(targets: [AXTarget], mode: OverlayMode, query: String = "", activeTargetID: Int? = nil, keyHandler: @escaping (KeyPress) -> Bool) {
        close()
        for screen in NSScreen.screens {
            let view = OverlayView(frame: screen.frame)
            view.targets = targets.filter { screen.frame.intersects(ScreenCoordinates.cocoaRect(fromAccessibilityRect: $0.frame)) }
            view.mode = mode
            view.query = query
            view.activeTargetID = activeTargetID
            let window = OverlayWindow(screen: screen, view: view)
            windows.append(window)
            views.append(view)
        }
        keyboard.onKeyPress = keyHandler
        keyboard.start()
        AppLogger.log("overlay show mode=\(mode) targets=\(targets.count) active=\(activeTargetID.map(String.init) ?? "none")")
    }

    func update(query: String) {
        views.forEach { $0.query = query }
    }

    func update(activeTargetID: Int?) {
        views.forEach { $0.activeTargetID = activeTargetID }
    }

    func close() {
        keyboard.stop()
        keyboard.onKeyPress = nil
        if !windows.isEmpty {
            AppLogger.log("overlay close")
        }
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        views.removeAll()
    }
}
