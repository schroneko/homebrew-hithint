import Foundation

final class ScrollModeController {
    private let scanner = AXScanner()
    private let overlays = OverlayCoordinator()
    private var targets: [AXTarget] = []
    private var activeIndex = 0
    private(set) var isActive = false
    private let jumpAmount: Int32 = 500000

    func activate() {
        isActive = true
        targets = scanner.scrollTargets()
        activeIndex = defaultIndex()
        AppLogger.log("scroll targets=\(targets.count) default=\(activeIndex + 1)")
        guard !targets.isEmpty else {
            isActive = false
            return
        }
        overlays.show(targets: targets, mode: .scroll, activeTargetID: activeTarget?.id) { [weak self] press in
            self?.handle(press) ?? false
        }
    }

    func cancel() {
        isActive = false
        overlays.close()
        targets.removeAll()
        activeIndex = 0
    }


    private func handle(_ press: KeyPress) -> Bool {
        if press.isEscape {
            cancel()
            return true
        }
        if !press.isRepeat && press.isCommandDown && press.isShiftDown && (press.isSpace || press.character == "j") {
            cancel()
            return true
        }
        if press.isCommandDown {
            return true
        }
        if let character = press.character, let number = Int(character), number > 0, number <= targets.count {
            activeIndex = number - 1
            overlays.update(activeTargetID: activeTarget?.id)
            return true
        }
        if press.keyCode == 48 {
            guard !targets.isEmpty else {
                return true
            }
            if press.isShiftDown {
                activeIndex = (activeIndex + targets.count - 1) % targets.count
            } else {
                activeIndex = (activeIndex + 1) % targets.count
            }
            overlays.update(activeTargetID: activeTarget?.id)
            return true
        }
        let multiplier: Int32 = press.isShiftDown ? 5 : 1
        let amount: Int32 = 40 * multiplier
        guard let target = activeTarget, let character = scrollCharacter(for: press) else {
            return true
        }
        let halfPage = Int32(target.frame.height / 2)
        switch character {
        case "h":
            ScrollPerformer.scroll(target: target, dx: amount, dy: 0)
        case "j":
            ScrollPerformer.scroll(target: target, dx: 0, dy: -amount)
        case "k":
            ScrollPerformer.scroll(target: target, dx: 0, dy: amount)
        case "l":
            ScrollPerformer.scroll(target: target, dx: -amount, dy: 0)
        case "d":
            ScrollPerformer.scroll(target: target, dx: 0, dy: -halfPage)
        case "u":
            ScrollPerformer.scroll(target: target, dx: 0, dy: halfPage)
        case "g":
            ScrollPerformer.scroll(target: target, dx: 0, dy: press.isShiftDown ? -jumpAmount : jumpAmount)
        default:
            break
        }
        return true
    }

    private func scrollCharacter(for press: KeyPress) -> String? {
        switch press.keyCode {
        case 123: return "h"
        case 124: return "l"
        case 125: return "j"
        case 126: return "k"
        default: return press.character
        }
    }

    private var activeTarget: AXTarget? {
        guard targets.indices.contains(activeIndex) else {
            return nil
        }
        return targets[activeIndex]
    }

    private func defaultIndex() -> Int {
        let areas = targets.map { $0.frame.width * $0.frame.height }
        guard let largest = areas.max(), let index = areas.firstIndex(of: largest) else {
            return 0
        }
        return index
    }
}
