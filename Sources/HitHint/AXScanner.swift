import AppKit
import ApplicationServices

struct AXTarget: Identifiable {
    let id: Int
    let element: AXUIElement
    let frame: CGRect
    var label: String
    let title: String
    let role: String
    let canPress: Bool
    let canScroll: Bool
}

final class AXScanner {
    private var nextID = 0
    private let maxElements = 900
    private let maxDepth = 14
    private let maxScrollTargets = 9

    func clickableTargets() -> [AXTarget] {
        let roots = frontmostRoots(includeMenuBar: true)
        var targets: [AXTarget] = []
        var visited = Set<AXUIElementWrapper>()
        for root in roots {
            collect(element: root, depth: 0, targets: &targets, visited: &visited, mode: .click)
            if targets.count >= maxElements {
                break
            }
        }
        return assignLabels(to: deduplicate(targets))
    }

    func scrollTargets() -> [AXTarget] {
        let roots = frontmostRoots(includeMenuBar: false)
        var targets: [AXTarget] = []
        var visited = Set<AXUIElementWrapper>()
        for root in roots {
            collect(element: root, depth: 0, targets: &targets, visited: &visited, mode: .scroll)
            if targets.count >= maxElements {
                break
            }
        }
        let deduplicated = Array(deduplicate(targets).prefix(maxScrollTargets))
        let chosen = deduplicated.isEmpty ? Array(deduplicate(fallbackScrollTargets(from: roots)).prefix(maxScrollTargets)) : deduplicated
        return assignNumberLabels(to: chosen)
    }

    private enum Mode {
        case click
        case scroll
    }

    private func frontmostRoots(includeMenuBar: Bool) -> [AXUIElement] {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return []
        }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var roots: [AXUIElement] = []
        if let focused = copyElement(appElement, kAXFocusedWindowAttribute) {
            roots.append(focused)
        } else if let main = copyElement(appElement, kAXMainWindowAttribute) {
            roots.append(main)
        } else if let windows = copyArray(appElement, kAXWindowsAttribute) {
            roots.append(contentsOf: windows.filter { !isMinimized($0) })
        }
        if includeMenuBar, let menu = copyElement(appElement, kAXMenuBarAttribute) {
            roots.append(menu)
        }
        if roots.isEmpty {
            roots.append(appElement)
        }
        return roots
    }

    private func collect(element: AXUIElement, depth: Int, targets: inout [AXTarget], visited: inout Set<AXUIElementWrapper>, mode: Mode) {
        if depth > maxDepth || targets.count >= maxElements {
            return
        }
        let wrapper = AXUIElementWrapper(element: element)
        if visited.contains(wrapper) {
            return
        }
        visited.insert(wrapper)

        if let target = makeTarget(from: element, mode: mode) {
            targets.append(target)
        }

        for child in children(of: element) {
            collect(element: child, depth: depth + 1, targets: &targets, visited: &visited, mode: mode)
        }
    }

    private func makeTarget(from element: AXUIElement, mode: Mode) -> AXTarget? {
        guard let role = copyString(element, kAXRoleAttribute) else {
            return nil
        }
        guard let frame = frame(of: element), isUsable(frame: frame) else {
            return nil
        }
        let actions = copyActionNames(element)
        let canPress = actions.contains(kAXPressAction as String) || actions.contains(kAXShowMenuAction as String)
        let canScroll = role == kAXScrollAreaRole as String
        let clickableRoles = [
            kAXButtonRole as String,
            kAXCheckBoxRole as String,
            kAXRadioButtonRole as String,
            kAXPopUpButtonRole as String,
            kAXMenuButtonRole as String,
            kAXMenuItemRole as String,
            "AXLink",
            kAXTextFieldRole as String,
            kAXTextAreaRole as String,
            kAXComboBoxRole as String,
            kAXSliderRole as String,
            kAXCellRole as String
        ]
        if mode == .click && !canPress && !clickableRoles.contains(role) {
            return nil
        }
        if mode == .scroll && !canScroll {
            return nil
        }
        nextID += 1
        return AXTarget(id: nextID, element: element, frame: frame, label: "", title: bestTitle(for: element), role: role, canPress: canPress, canScroll: canScroll)
    }

    private func fallbackScrollTargets(from roots: [AXUIElement]) -> [AXTarget] {
        var targets: [AXTarget] = []
        for root in roots {
            guard let role = copyString(root, kAXRoleAttribute),
                  role == kAXWindowRole as String,
                  let frame = frame(of: root),
                  isUsable(frame: frame) else {
                continue
            }
            nextID += 1
            targets.append(AXTarget(id: nextID, element: root, frame: frame, label: "", title: bestTitle(for: root), role: "AXWindowScrollFallback", canPress: false, canScroll: true))
        }
        if targets.isEmpty, let screen = NSScreen.main {
            let appElement = AXUIElementCreateSystemWide()
            nextID += 1
            targets.append(AXTarget(id: nextID, element: appElement, frame: screen.frame.insetBy(dx: 80, dy: 80), label: "", title: "Main Screen", role: "ScreenScrollFallback", canPress: false, canScroll: true))
        }
        return targets
    }

    private func frame(of element: AXUIElement) -> CGRect? {
        guard let position = copyValue(element, kAXPositionAttribute),
              let size = copyValue(element, kAXSizeAttribute) else {
            return nil
        }
        var point = CGPoint.zero
        var cgSize = CGSize.zero
        AXValueGetValue(position, .cgPoint, &point)
        AXValueGetValue(size, .cgSize, &cgSize)
        return CGRect(origin: point, size: cgSize)
    }

    private func isUsable(frame: CGRect) -> Bool {
        guard frame.origin.x.isFinite, frame.origin.y.isFinite, frame.width.isFinite, frame.height.isFinite else {
            return false
        }
        if frame.width < 4 || frame.height < 4 {
            return false
        }
        let cocoaFrame = ScreenCoordinates.cocoaRect(fromAccessibilityRect: frame)
        return NSScreen.screens.contains { $0.frame.intersects(cocoaFrame) }
    }

    private func children(of element: AXUIElement) -> [AXUIElement] {
        let keys = [
            kAXVisibleChildrenAttribute,
            kAXChildrenAttribute,
            "AXRows",
            "AXColumns",
            "AXContents"
        ]
        var output: [AXUIElement] = []
        for key in keys {
            output.append(contentsOf: copyArray(element, key) ?? [])
        }
        return output
    }

    private func bestTitle(for element: AXUIElement) -> String {
        let keys = [
            kAXTitleAttribute,
            kAXDescriptionAttribute,
            kAXHelpAttribute,
            kAXValueAttribute,
            "AXPlaceholderValue",
            "AXIdentifier"
        ]
        for key in keys {
            if let value = copyString(element, key), !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }
        return ""
    }

    private func assignLabels(to targets: [AXTarget]) -> [AXTarget] {
        let alphabet = Array("asdfjklghqwertyuiopzxcvbnm").map(String.init)
        var labels: [String] = []
        var width = 1
        while labels.count < targets.count {
            labels = makeLabels(alphabet: alphabet, width: width)
            width += 1
        }
        return targets.enumerated().map { index, target in
            var copy = target
            copy.label = labels[index]
            return copy
        }
    }

    private func makeLabels(alphabet: [String], width: Int) -> [String] {
        if width == 1 {
            return alphabet
        }
        let smaller = makeLabels(alphabet: alphabet, width: width - 1)
        var output: [String] = []
        for first in alphabet {
            for suffix in smaller {
                output.append(first + suffix)
            }
        }
        return output
    }

    private func assignNumberLabels(to targets: [AXTarget]) -> [AXTarget] {
        targets.enumerated().map { index, target in
            var copy = target
            copy.label = "\(index + 1)"
            return copy
        }
    }

    private func deduplicate(_ targets: [AXTarget]) -> [AXTarget] {
        var seen = Set<String>()
        var output: [AXTarget] = []
        let ordered = targets.sorted {
            if $0.frame.minY != $1.frame.minY {
                return $0.frame.minY < $1.frame.minY
            }
            return $0.frame.minX < $1.frame.minX
        }
        for target in ordered {
            let key = "\(Int(target.frame.minX)):\(Int(target.frame.minY)):\(Int(target.frame.width)):\(Int(target.frame.height)):\(target.role)"
            if !seen.contains(key) {
                seen.insert(key)
                output.append(target)
            }
        }
        return output
    }

    private func isMinimized(_ element: AXUIElement) -> Bool {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXMinimizedAttribute as CFString, &value) == .success else {
            return false
        }
        return (value as? Bool) == true
    }

    private func copyElement(_ element: AXUIElement, _ key: String) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, key as CFString, &value) == .success,
              let value,
              CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }
        return (value as! AXUIElement)
    }

    private func copyArray(_ element: AXUIElement, _ key: String) -> [AXUIElement]? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, key as CFString, &value) == .success else {
            return nil
        }
        return value as? [AXUIElement]
    }

    private func copyString(_ element: AXUIElement, _ key: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, key as CFString, &value) == .success else {
            return nil
        }
        if let string = value as? String {
            return string
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return nil
    }

    private func copyActionNames(_ element: AXUIElement) -> [String] {
        var value: CFArray?
        guard AXUIElementCopyActionNames(element, &value) == .success else {
            return []
        }
        return value as? [String] ?? []
    }

    private func copyValue(_ element: AXUIElement, _ key: String) -> AXValue? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, key as CFString, &value) == .success,
              let value,
              CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }
        return (value as! AXValue)
    }
}

private struct AXUIElementWrapper: Hashable {
    let element: AXUIElement

    func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(element))
    }

    static func == (lhs: AXUIElementWrapper, rhs: AXUIElementWrapper) -> Bool {
        CFEqual(lhs.element, rhs.element)
    }
}
