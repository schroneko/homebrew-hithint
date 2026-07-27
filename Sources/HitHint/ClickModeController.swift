import Foundation

final class ClickModeController {
    private let scanner = AXScanner()
    private let overlays = OverlayCoordinator()
    private var targets: [AXTarget] = []
    private var query = ""
    private(set) var isActive = false

    func activate() {
        isActive = true
        query = ""
        targets = scanner.clickableTargets()
        AppLogger.log("click targets=\(targets.count)")
        guard !targets.isEmpty else {
            isActive = false
            return
        }
        overlays.show(targets: targets, mode: .click) { [weak self] press in
            self?.handle(press) ?? false
        }
    }

    func cancel() {
        isActive = false
        overlays.close()
        targets.removeAll()
        query = ""
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
        if press.isDelete {
            if !query.isEmpty {
                query.removeLast()
                overlays.update(query: query)
            }
            return true
        }
        if press.isReturn || press.isSpace {
            if let target = targets.first(where: { $0.label == query }) {
                AppLogger.log("click label=\(target.label) role=\(target.role) title=\(target.title)")
                ClickPerformer.click(target: target, rightClick: press.isShiftDown, commandClick: press.isCommandDown)
                cancel()
            }
            return true
        }
        guard let character = press.character, character.rangeOfCharacter(from: .letters) != nil else {
            return true
        }
        let nextQuery = query + character
        let matches = targets.filter { $0.label.hasPrefix(nextQuery) }
        guard !matches.isEmpty else {
            return true
        }
        query = nextQuery
        overlays.update(query: query)
        if matches.count == 1, matches[0].label == query {
            AppLogger.log("click label=\(matches[0].label) role=\(matches[0].role) title=\(matches[0].title)")
            ClickPerformer.click(target: matches[0], rightClick: press.isShiftDown, commandClick: press.isCommandDown)
            cancel()
        }
        return true
    }
}
