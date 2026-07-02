import AppKit

struct KeyPress {
    let keyCode: Int64
    let character: String?
    let isShiftDown: Bool
    let isCommandDown: Bool
    let isReturn: Bool
    let isEscape: Bool
    let isDelete: Bool
    let isSpace: Bool

    static func from(event: NSEvent) -> KeyPress {
        let code = Int64(event.keyCode)
        let flags = event.modifierFlags
        return KeyPress(
            keyCode: code,
            character: KeyMap.character(for: code),
            isShiftDown: flags.contains(.shift),
            isCommandDown: flags.contains(.command),
            isReturn: code == 36 || code == 76,
            isEscape: code == 53,
            isDelete: code == 51,
            isSpace: code == 49
        )
    }
}
