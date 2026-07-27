import Carbon.HIToolbox
import Foundation

final class HotKeyManager {
    var onClickMode: (() -> Void)?
    var onScrollMode: (() -> Void)?
    private var handlerRef: EventHandlerRef?
    private var clickRef: EventHotKeyRef?
    private var scrollRef: EventHotKeyRef?
    private var pressedIDs = Set<UInt32>()
    private var lastFire: [UInt32: TimeInterval] = [:]
    private let signature = OSType(0x484C4954)

    func start() {
        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]
        InstallEventHandler(GetEventDispatcherTarget(), { _, event, userData in
            guard let userData, let event else {
                return noErr
            }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            if status == noErr {
                let kind = GetEventKind(event)
                DispatchQueue.main.async {
                    if kind == UInt32(kEventHotKeyPressed) {
                        manager.pressed(id: hotKeyID.id)
                    } else if kind == UInt32(kEventHotKeyReleased) {
                        manager.released(id: hotKeyID.id)
                    }
                }
            }
            return noErr
        }, 2, &eventTypes, Unmanaged.passUnretained(self).toOpaque(), &handlerRef)

        let clickID = EventHotKeyID(signature: signature, id: 1)
        RegisterEventHotKey(UInt32(kVK_Space), UInt32(cmdKey | shiftKey), clickID, GetEventDispatcherTarget(), 0, &clickRef)
        let scrollID = EventHotKeyID(signature: signature, id: 2)
        RegisterEventHotKey(UInt32(kVK_ANSI_J), UInt32(cmdKey | shiftKey), scrollID, GetEventDispatcherTarget(), 0, &scrollRef)
    }

    private func pressed(id: UInt32) {
        let now = ProcessInfo.processInfo.systemUptime
        if pressedIDs.contains(id) {
            if let last = lastFire[id], now - last > 2 {
                pressedIDs.remove(id)
            } else {
                return
            }
        }
        pressedIDs.insert(id)
        if let last = lastFire[id], now - last < 0.3 {
            return
        }
        lastFire[id] = now
        if id == 1 {
            onClickMode?()
        } else if id == 2 {
            onScrollMode?()
        }
    }

    private func released(id: UInt32) {
        pressedIDs.remove(id)
    }
}
