import Carbon.HIToolbox
import Foundation

final class HotKeyManager {
    var onClickMode: (() -> Void)?
    var onScrollMode: (() -> Void)?
    private var handlerRef: EventHandlerRef?
    private var clickRef: EventHotKeyRef?
    private var scrollRef: EventHotKeyRef?
    private let signature = OSType(0x484C4954)

    func start() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), { _, event, userData in
            guard let userData else {
                return noErr
            }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            if status == noErr {
                DispatchQueue.main.async {
                    manager.fire(id: hotKeyID.id)
                }
            }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handlerRef)

        var clickID = EventHotKeyID(signature: signature, id: 1)
        RegisterEventHotKey(UInt32(kVK_Space), UInt32(cmdKey | shiftKey), clickID, GetEventDispatcherTarget(), 0, &clickRef)
        var scrollID = EventHotKeyID(signature: signature, id: 2)
        RegisterEventHotKey(UInt32(kVK_ANSI_J), UInt32(cmdKey | shiftKey), scrollID, GetEventDispatcherTarget(), 0, &scrollRef)
    }

    private func fire(id: UInt32) {
        if id == 1 {
            onClickMode?()
        } else if id == 2 {
            onScrollMode?()
        }
    }
}
