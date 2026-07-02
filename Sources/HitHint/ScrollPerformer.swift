import AppKit

enum ScrollPerformer {
    static func scroll(target: AXTarget, dx: Int32, dy: Int32) {
        let source = CGEventSource(stateID: .hidSystemState)
        guard let event = CGEvent(scrollWheelEvent2Source: source, units: .pixel, wheelCount: 2, wheel1: dy, wheel2: dx, wheel3: 0) else {
            return
        }
        event.location = CGPoint(x: target.frame.midX, y: target.frame.midY)
        event.post(tap: .cghidEventTap)
    }
}
