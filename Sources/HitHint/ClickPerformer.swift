import AppKit
import ApplicationServices

enum ClickPerformer {
    static func click(target: AXTarget, rightClick: Bool, commandClick: Bool) {
        if target.canPress && !rightClick && !commandClick {
            let result = AXUIElementPerformAction(target.element, kAXPressAction as CFString)
            if result == .success {
                return
            }
        }
        let point = CGPoint(x: target.frame.midX, y: target.frame.midY)
        postMouseClick(at: point, rightClick: rightClick, commandClick: commandClick)
    }

    private static func postMouseClick(at point: CGPoint, rightClick: Bool, commandClick: Bool) {
        let button: CGMouseButton = rightClick ? .right : .left
        let downType: CGEventType = rightClick ? .rightMouseDown : .leftMouseDown
        let upType: CGEventType = rightClick ? .rightMouseUp : .leftMouseUp
        let source = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(mouseEventSource: source, mouseType: downType, mouseCursorPosition: point, mouseButton: button)
        let up = CGEvent(mouseEventSource: source, mouseType: upType, mouseCursorPosition: point, mouseButton: button)
        if commandClick {
            down?.flags = .maskCommand
            up?.flags = .maskCommand
        }
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
