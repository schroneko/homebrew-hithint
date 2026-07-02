import AppKit

final class PermissionViewController: NSViewController {
    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 190))
        let title = NSTextField(labelWithString: "Accessibility permission is required")
        title.font = .boldSystemFont(ofSize: 18)
        title.frame = NSRect(x: 24, y: 132, width: 410, height: 28)

        let body = NSTextField(wrappingLabelWithString: "HitHint uses macOS Accessibility to find visible UI elements and click or scroll them from the keyboard.")
        body.frame = NSRect(x: 24, y: 72, width: 410, height: 48)

        let button = NSButton(title: "Open System Settings", target: self, action: #selector(openSettings))
        button.bezelStyle = .rounded
        button.frame = NSRect(x: 24, y: 24, width: 170, height: 32)

        root.addSubview(title)
        root.addSubview(body)
        root.addSubview(button)
        view = root
    }

    @objc private func openSettings() {
        AXPermission.prompt()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
