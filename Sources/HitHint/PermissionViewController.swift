import AppKit

final class PermissionViewController: NSViewController {
    private var pollTimer: Timer?

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 248))
        let title = NSTextField(labelWithString: "Accessibility permission is required")
        title.font = .boldSystemFont(ofSize: 18)
        title.frame = NSRect(x: 24, y: 190, width: 432, height: 28)

        let body = NSTextField(wrappingLabelWithString: "HitHint uses macOS Accessibility to find visible UI elements and click or scroll them from the keyboard.")
        body.frame = NSRect(x: 24, y: 130, width: 432, height: 48)

        let hint = NSTextField(wrappingLabelWithString: "If HitHint doesn't appear in the Accessibility list, drag the app from Finder into the open System Settings panel.")
        hint.textColor = .secondaryLabelColor
        hint.frame = NSRect(x: 24, y: 70, width: 432, height: 44)

        let settingsButton = NSButton(title: "Open System Settings", target: self, action: #selector(openSettings))
        settingsButton.bezelStyle = .rounded
        settingsButton.keyEquivalent = "\r"
        settingsButton.frame = NSRect(x: 24, y: 22, width: 190, height: 32)

        let finderButton = NSButton(title: "Show HitHint in Finder", target: self, action: #selector(showInFinder))
        finderButton.bezelStyle = .rounded
        finderButton.frame = NSRect(x: 222, y: 22, width: 190, height: 32)

        root.addSubview(title)
        root.addSubview(body)
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
