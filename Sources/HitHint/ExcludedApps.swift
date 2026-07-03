import AppKit

enum ExcludedApps {
    static let changedNotification = Notification.Name("HitHintExcludedAppsChanged")
    private static let key = "excluded-bundle-ids"

    static var bundleIdentifiers: [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    static func contains(_ bundleIdentifier: String?) -> Bool {
        guard let id = bundleIdentifier else { return false }
        return bundleIdentifiers.contains(id)
    }

    static func add(_ bundleIdentifier: String) {
        var ids = bundleIdentifiers
        guard !ids.contains(bundleIdentifier) else { return }
        ids.append(bundleIdentifier)
        UserDefaults.standard.set(ids, forKey: key)
        NotificationCenter.default.post(name: changedNotification, object: nil)
    }

    static func remove(_ bundleIdentifier: String) {
        let ids = bundleIdentifiers.filter { $0 != bundleIdentifier }
        UserDefaults.standard.set(ids, forKey: key)
        NotificationCenter.default.post(name: changedNotification, object: nil)
    }

    static func displayName(for bundleIdentifier: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return bundleIdentifier
        }
        let name = FileManager.default.displayName(atPath: url.path)
        return name.hasSuffix(".app") ? String(name.dropLast(4)) : name
    }

    static func icon(for bundleIdentifier: String) -> NSImage {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(for: .applicationBundle)
    }
}
