import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let hotKeys = HotKeyManager()
    private lazy var clickMode = ClickModeController()
    private lazy var scrollMode = ScrollModeController()
    private var statusItem: NSStatusItem?
    private var permissionWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AppLogger.log("launched path=\(Bundle.main.bundlePath) trusted=\(AXPermission.isTrusted)")
        installMenu()
        hotKeys.onClickMode = { [weak self] in self?.activateClickMode() }
        hotKeys.onScrollMode = { [weak self] in self?.activateScrollMode() }
        hotKeys.start()
        if !AXPermission.isTrusted {
            showPermissionWindow()
        }
    }

    private func installMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "HH"
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Click Labels", action: #selector(clickLabels), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Scroll Mode", action: #selector(scrollLabels), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Grant Accessibility", action: #selector(grantAccessibility), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: ""))
        item.menu = menu
        statusItem = item
    }

    @objc private func clickLabels() {
        activateClickMode()
    }

    @objc private func scrollLabels() {
        activateScrollMode()
    }

    @objc private func grantAccessibility() {
        AXPermission.prompt()
        showPermissionWindow()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func activateClickMode() {
        AppLogger.log("activate click requested trusted=\(AXPermission.isTrusted)")
        guard AXPermission.ensureTrusted() else {
            showPermissionWindow()
            return
        }
        scrollMode.cancel()
        clickMode.activate()
    }

    private func activateScrollMode() {
        AppLogger.log("activate scroll requested trusted=\(AXPermission.isTrusted)")
        guard AXPermission.ensureTrusted() else {
            showPermissionWindow()
            return
        }
        clickMode.cancel()
        scrollMode.activate()
    }

    private func showPermissionWindow() {
        if permissionWindow != nil {
            permissionWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let controller = PermissionViewController()
        let window = NSWindow(contentViewController: controller)
        window.title = "HitHint"
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false
        permissionWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
