import AppKit

final class OverlayCoordinator {
    private var windows: [OverlayWindow] = []
    private var views: [OverlayView] = []

    func show(targets: [AXTarget], mode: OverlayMode, query: String = "", activeTargetID: Int? = nil, keyHandler: @escaping (KeyPress) -> Bool) {
        close()
        for screen in NSScreen.screens {
            let view = OverlayView(frame: screen.frame)
            view.targets = targets.filter { screen.frame.intersects($0.frame) }
            view.mode = mode
            view.query = query
            view.activeTargetID = activeTargetID
            let window = OverlayWindow(screen: screen, view: view)
            window.keyHandler = keyHandler
            windows.append(window)
            views.append(view)
        }
        NSApp.activate(ignoringOtherApps: true)
        windows.first(where: { $0.screen == NSScreen.main })?.makeKeyAndOrderFront(nil)
        windows.first?.makeKeyAndOrderFront(nil)
    }

    func update(query: String) {
        views.forEach { $0.query = query }
    }

    func update(activeTargetID: Int?) {
        views.forEach { $0.activeTargetID = activeTargetID }
    }

    func close() {
        NSApp.hide(nil)
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        views.removeAll()
    }
}
