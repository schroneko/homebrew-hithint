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
    let isRepeat: Bool

    static func from(cgEvent: CGEvent) -> KeyPress {
        let code = cgEvent.getIntegerValueField(.keyboardEventKeycode)
        let flags = cgEvent.flags
        return KeyPress(
            keyCode: code,
            character: KeyMap.character(for: code),
            isShiftDown: flags.contains(.maskShift),
            isCommandDown: flags.contains(.maskCommand),
            isReturn: code == 36 || code == 76,
            isEscape: code == 53,
            isDelete: code == 51,
            isSpace: code == 49,
            isRepeat: cgEvent.getIntegerValueField(.keyboardEventAutorepeat) != 0
        )
    }
}

final class KeyboardEventTap {
    static let shared = KeyboardEventTap()
    var onKeyPress: ((KeyPress) -> Bool)?
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() {
        guard tap == nil else { return }
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue) | CGEventMask(1 << CGEventType.keyUp.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }
            let instance = Unmanaged<KeyboardEventTap>.fromOpaque(userInfo).takeUnretainedValue()
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                instance.reenable()
                return Unmanaged.passUnretained(event)
            }
            guard instance.onKeyPress != nil else {
                return Unmanaged.passUnretained(event)
            }
            let press = KeyPress.from(cgEvent: event)
            if press.isCommandDown && press.keyCode == 48 {
                return Unmanaged.passUnretained(event)
            }
            if type == .keyUp {
                return nil
            }
            DispatchQueue.main.async {
                _ = instance.onKeyPress?(press)
            }
            return nil
        }
        tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        guard let tap else {
            AppLogger.log("keyboard tap creation failed")
            return
        }
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        tap = nil
        runLoopSource = nil
    }

    private func reenable() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }
}
