import Foundation

final class ScrollModeController {
    private let scanner = AXScanner()
    private let overlays = OverlayCoordinator()
    private var targets: [AXTarget] = []
    private var activeIndex = 0

    func activate() {
        targets = scanner.scrollTargets()
        activeIndex = 0
        AppLogger.log("scroll targets=\(targets.count)")
        overlays.show(targets: targets, mode: .scroll, activeTargetID: activeTarget?.id) { [weak self] press in
            self?.handle(press) ?? false
        }
    }

    func cancel() {
        overlays.close()
        targets.removeAll()
        activeIndex = 0
    }

    private func handle(_ press: KeyPress) -> Bool {
        if press.isEscape {
            cancel()
            return true
        }
        if let character = press.character, let number = Int(character), number > 0, number <= targets.count {
            activeIndex = number - 1
            overlays.update(activeTargetID: activeTarget?.id)
            return true
        }
        let multiplier: Int32 = press.isShiftDown ? 5 : 1
        let amount: Int32 = 80 * multiplier
        guard let target = activeTarget, let character = press.character else {
            return true
        }
        switch character {
        case "h":
            ScrollPerformer.scroll(target: target, dx: amount, dy: 0)
        case "j":
            ScrollPerformer.scroll(target: target, dx: 0, dy: -amount)
        case "k":
            ScrollPerformer.scroll(target: target, dx: 0, dy: amount)
        case "l":
            ScrollPerformer.scroll(target: target, dx: -amount, dy: 0)
        default:
            break
        }
        return true
    }

    private var activeTarget: AXTarget? {
        guard targets.indices.contains(activeIndex) else {
            return nil
        }
        return targets[activeIndex]
    }
}
