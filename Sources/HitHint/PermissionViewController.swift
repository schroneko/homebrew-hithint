import AppKit

final class PermissionViewController: NSViewController {
    private var pollTimer: Timer?

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 320))
        let title = NSTextField(labelWithString: "Accessibility permission is required")
        title.font = .boldSystemFont(ofSize: 18)
        title.frame = NSRect(x: 24, y: 262, width: 432, height: 28)

        let body = NSTextField(wrappingLabelWithString: "HitHint uses macOS Accessibility to find visible UI elements and click or scroll them from the keyboard.")
        body.frame = NSRect(x: 24, y: 202, width: 432, height: 48)

        let icon = AppIconDragView(frame: NSRect(x: 24, y: 106, width: 72, height: 72))
        icon.image = NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.toolTip = "Drag HitHint into the Accessibility settings"

        let hint = NSTextField(wrappingLabelWithString: "If HitHint doesn't appear in the Accessibility list, drag this app icon into the open System Settings panel.")
        hint.textColor = .secondaryLabelColor
        hint.frame = NSRect(x: 112, y: 118, width: 344, height: 48)

        let settingsButton = NSButton(title: "Open System Settings", target: self, action: #selector(openSettings))
        settingsButton.bezelStyle = .rounded
        settingsButton.keyEquivalent = "\r"
        settingsButton.frame = NSRect(x: 24, y: 22, width: 190, height: 32)

        let finderButton = NSButton(title: "Show HitHint in Finder", target: self, action: #selector(showInFinder))
        finderButton.bezelStyle = .rounded
        finderButton.frame = NSRect(x: 222, y: 22, width: 190, height: 32)

        root.addSubview(title)
        root.addSubview(body)
        root.addSubview(icon)
        root.addSubview(hint)
        root.addSubview(settingsButton)
        root.addSubview(finderButton)
        view = root
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard AXPermission.isTrusted else { return }
            AppLogger.log("accessibility granted, closing permission window")
            self?.view.window?.close()
        }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        pollTimer?.invalidate()
        pollTimer = nil
    }

    @objc private func openSettings() {
        AXPermission.prompt()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func showInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }
}

final class AppIconDragView: NSImageView, NSDraggingSource {
    override init(frame: NSRect) {
        super.init(frame: frame)
        unregisterDraggedTypes()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        let item = NSDraggingItem(pasteboardWriter: Bundle.main.bundleURL as NSURL)
        item.setDraggingFrame(bounds, contents: image)
        beginDraggingSession(with: [item], event: event, source: self)
        AppLogger.log("app icon drag started")
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        context == .outsideApplication ? .copy : []
    }
}
