import Foundation

final class ClickModeController {
    private let scanner = AXScanner()
    private let overlays = OverlayCoordinator()
    private var targets: [AXTarget] = []
    private var query = ""

    func activate() {
        query = ""
        targets = scanner.clickableTargets()
        AppLogger.log("click targets=\(targets.count)")
        overlays.show(targets: targets, mode: .click) { [weak self] press in
            self?.handle(press) ?? false
        }
    }

    func cancel() {
        overlays.close()
        targets.removeAll()
        query = ""
    }

    private func handle(_ press: KeyPress) -> Bool {
        if press.isEscape {
            cancel()
            return true
        }
        if press.isDelete {
            if !query.isEmpty {
                query.removeLast()
                overlays.update(query: query)
            }
            return true
        }
        if press.isReturn || press.isSpace {
            if let target = exactTarget() {
                AppLogger.log("click label=\(target.label) role=\(target.role) title=\(target.title)")
                ClickPerformer.click(target: target, rightClick: press.isShiftDown, commandClick: press.isCommandDown)
                cancel()
            }
            return true
        }
        guard let character = press.character, character.rangeOfCharacter(from: .letters) != nil else {
            return true
        }
        query.append(character)
        overlays.update(query: query)
        let exact = exactMatches()
        let possible = targets.filter { $0.label.hasPrefix(query) }
        if exact.count == 1 && possible.count == 1 {
            AppLogger.log("click label=\(exact[0].label) role=\(exact[0].role) title=\(exact[0].title)")
            ClickPerformer.click(target: exact[0], rightClick: press.isShiftDown, commandClick: press.isCommandDown)
            cancel()
        }
        return true
    }

    private func exactTarget() -> AXTarget? {
        exactMatches().first
    }

    private func exactMatches() -> [AXTarget] {
        targets.filter { $0.label == query }
    }
}
