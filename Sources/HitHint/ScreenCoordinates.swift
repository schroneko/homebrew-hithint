import AppKit

enum ScreenCoordinates {
    static var primaryScreenHeight: CGFloat {
        let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero }) ?? NSScreen.screens.first
        return primary?.frame.maxY ?? 0
    }

    static func cocoaRect(fromAccessibilityRect rect: CGRect) -> CGRect {
        CGRect(
            x: rect.minX,
            y: primaryScreenHeight - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
}
