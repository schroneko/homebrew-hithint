import ServiceManagement

enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            AppLogger.log("launch at login set enabled=\(enabled) status=\(SMAppService.mainApp.status.rawValue)")
        } catch {
            AppLogger.log("launch at login change failed: \(error.localizedDescription)")
        }
    }
}
