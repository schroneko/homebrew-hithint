import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let hotKeys = HotKeyManager()
    private lazy var clickMode = ClickModeController()
    private lazy var scrollMode = ScrollModeController()
    private var statusItem: NSStatusItem?
    private var permissionWindow: NSWindow?
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AppLogger.log("launched path=\(Bundle.main.bundlePath) trusted=\(AXPermission.isTrusted)")
        terminateDuplicateInstances()
        installMenu()
        if !UserDefaults.standard.bool(forKey: "launch-at-login-default-applied") {
            UserDefaults.standard.set(true, forKey: "launch-at-login-default-applied")
            LaunchAtLogin.setEnabled(true)
        }
        hotKeys.onClickMode = { [weak self] in self?.activateClickMode() }
        hotKeys.onScrollMode = { [weak self] in self?.activateScrollMode() }
        hotKeys.start()
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self, self.clickMode.isActive || self.scrollMode.isActive else {
                return
            }
            AppLogger.log("frontmost app changed, dismissing overlay")
            self.clickMode.cancel()
            self.scrollMode.cancel()
        }
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, self.clickMode.isActive || self.scrollMode.isActive else {
                return
            }
            AppLogger.log("mouse click, dismissing overlay")
            self.clickMode.cancel()
            self.scrollMode.cancel()
        }
        if !AXPermission.isTrusted {
            showPermissionWindow()
        }
    }

    func applicationDidResignActive(_ notification: Notification) {
        if clickMode.isActive || scrollMode.isActive {
            AppLogger.log("app resigned active, dismissing overlay")
            clickMode.cancel()
            scrollMode.cancel()
        }
    }

    private func terminateDuplicateInstances() {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return
        }
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let duplicates = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != currentPID }
        for duplicate in duplicates {
            AppLogger.log("terminating duplicate instance pid=\(duplicate.processIdentifier)")
            duplicate.forceTerminate()
        }
    }

    private func installMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "HH"
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Click Labels", action: #selector(clickLabels), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Scroll Mode", action: #selector(scrollLabels), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ""))
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

    @objc private func openSettings() {
        AppLogger.log("open settings requested")
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        AppLogger.log("open settings visible=\(settingsWindowController?.window?.isVisible ?? false)")
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
        if clickMode.isActive || scrollMode.isActive {
            AppLogger.log("click hotkey toggled overlay off")
            clickMode.cancel()
            scrollMode.cancel()
            return
        }
        if ExcludedApps.contains(NSWorkspace.shared.frontmostApplication?.bundleIdentifier) {
            AppLogger.log("click mode skipped: frontmost app is excluded")
            return
        }
        clickMode.activate()
    }

    private func activateScrollMode() {
        AppLogger.log("activate scroll requested trusted=\(AXPermission.isTrusted)")
        guard AXPermission.ensureTrusted() else {
            showPermissionWindow()
            return
        }
        if clickMode.isActive || scrollMode.isActive {
            AppLogger.log("scroll hotkey toggled overlay off")
            clickMode.cancel()
            scrollMode.cancel()
            return
        }
        if ExcludedApps.contains(NSWorkspace.shared.frontmostApplication?.bundleIdentifier) {
            AppLogger.log("scroll mode skipped: frontmost app is excluded")
            return
        }
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
