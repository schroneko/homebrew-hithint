import ApplicationServices

enum AXPermission {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func ensureTrusted() -> Bool {
        if isTrusted {
            return true
        }
        prompt()
        return false
    }

    static func prompt() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
