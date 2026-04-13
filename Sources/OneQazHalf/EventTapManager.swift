import AppKit
import Carbon
import CoreGraphics

final class EventTapManager {

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // MARK: - 功能開關
    var isRunning: Bool { tap != nil }

    // MARK: - 注音組字狀態追蹤
    private var hasPendingBopomofo = false
    private static let commitKeys: Set<CGKeyCode> = [36, 53, 49] // Return, Escape, Space
    private func clearBopomofoInput() { hasPendingBopomofo = false }

    var shiftLetterEnabled  = true  // Shift + 字母 → 小寫半形英文
    var shiftNumberEnabled  = true  // Shift + 數字列 → 半形符號
    var shiftPunctEnabled   = true  // Shift + 標點 → 半形標點
    var numpadEnabled       = true  // 九宮格 → 半形數字

    // MARK: - 鍵碼對照表

    /// 英文字母 keyCode → 小寫字元
    static let letterKeys: [CGKeyCode: Character] = [
        0: "a", 11: "b",  8: "c",  2: "d", 14: "e",
        3: "f",  5: "g",  4: "h", 34: "i", 38: "j",
       40: "k", 37: "l", 46: "m", 45: "n", 31: "o",
       35: "p", 12: "q", 15: "r",  1: "s", 17: "t",
       32: "u",  9: "v", 13: "w",  7: "x", 16: "y", 6: "z"
    ]

    /// 數字列 Shift keyCode → 半形符號
    static let shiftNumberKeys: [CGKeyCode: Character] = [
        18: "!", 19: "@", 20: "#", 21: "$", 23: "%",
        22: "^", 26: "&", 28: "*", 25: "(", 29: ")",
        27: "_", 24: "+"
    ]

    /// Shift + 標點鍵 → 半形標點
    static let shiftPunctKeys: [CGKeyCode: Character] = [
        41: ":", 39: "\"", 44: "?", 43: "<", 47: ">",
        33: "{", 30: "}",  42: "|", 50: "~"
    ]

    /// 九宮格數字鍵 keyCode → 半形字元
    static let numpadKeys: [CGKeyCode: Character] = [
        83: "1", 84: "2", 85: "3",
        86: "4", 87: "5", 88: "6",
        89: "7", 91: "8", 92: "9",
        82: "0",
        65: ".", 69: "+", 78: "-", 67: "*", 75: "/", 81: "="
    ]

    // MARK: - 生命週期

    @discardableResult
    func start() -> Bool {
        stop()

        let trusted = AXIsProcessTrustedWithOptions(nil)
        print("[1qaz Half] AXIsTrusted = \(trusted)")
        guard trusted else {
            print("[1qaz Half] ✗ 沒有 Accessibility 權限")
            return false
        }

        let mask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.tapDisabledByTimeout.rawValue)

        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: globalTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("[1qaz Half] ✗ CGEvent.tapCreate 失敗（權限已給但仍失敗？）")
            return false
        }

        tap = port
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        print("[1qaz Half] ✓ Event tap 已啟動")
        return true
    }

    func stop() {
        if let port = tap { CGEvent.tapEnable(tap: port, enable: false) }
        if let src = runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes) }
        tap = nil
        runLoopSource = nil
        print("[1qaz Half] Event tap 已停用")
    }

    // MARK: - 事件處理

    fileprivate func process(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        guard InputSourceHelper.isBopomofoActive() else {
            return Unmanaged.passRetained(event)
        }

        let kc      = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let flags   = event.flags
        let shift   = flags.contains(.maskShift)
        let option  = flags.contains(.maskAlternate)
        let command = flags.contains(.maskCommand)
        let control = flags.contains(.maskControl)

        guard !command && !control && !option else { return Unmanaged.passRetained(event) }

        // ── Shift + 字母 → 小寫半形英文 ──────────────────────────────────
        if shiftLetterEnabled && shift, let ch = Self.letterKeys[kc] {
            log(trigger: "Shift+\(ch)", output: ch, feature: "半形英文")
            return inject(ch)
        }

        // ── Shift + 數字列 → 半形符號 ─────────────────────────────────────
        if shiftNumberEnabled && shift, let ch = Self.shiftNumberKeys[kc] {
            log(trigger: "Shift+數字", output: ch, feature: "半形數字符號")
            return inject(ch)
        }

        // ── Shift + 標點 → 半形標點 ──────────────────────────────────────
        if shiftPunctEnabled && shift, let ch = Self.shiftPunctKeys[kc] {
            log(trigger: "Shift+標點", output: ch, feature: "半形標點")
            return inject(ch)
        }

        // ── 九宮格數字鍵 → 半形數字 ──────────────────────────────────────
        if numpadEnabled, let ch = Self.numpadKeys[kc] {
            log(trigger: "Numpad", output: ch, feature: "九宮格半形")
            return inject(ch)
        }

        // 追蹤注音組字狀態：只有無修飾鍵的字母鍵才算真正的注音輸入
        if Self.commitKeys.contains(kc) {
            clearBopomofoInput()
        } else if !shift && !option, Self.letterKeys[kc] != nil {
            hasPendingBopomofo = true
        }
        return Unmanaged.passRetained(event)
    }

    private func log(trigger: String, output: Character, feature: String) {
        let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("[\(time)] [\(feature)] \(trigger)  →  \(output)")
    }

    fileprivate func reenable() {
        if let port = tap { CGEvent.tapEnable(tap: port, enable: true) }
    }

    // MARK: - 注入字元

    private func inject(_ char: Character) -> Unmanaged<CGEvent>? {
        if hasPendingBopomofo {
            clearBopomofoInput()
            // 有注音 buffer：切換到 ABC 讓 IME 自動取消組字，注入後切回
            // 用 ID 字串重新查找注音輸入法，避免引用失效
            let bopomofoID = InputSourceHelper.currentInputSourceID()
            if let ascii = findASCIILayout() {
                TISSelectInputSource(ascii)
                // 等 ABC 切換生效後注入字元，再切回注音
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.postChar(char)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        if let bopomofo = self.findInputSourceByID(bopomofoID) {
                            TISSelectInputSource(bopomofo)
                        }
                    }
                }
                return nil
            }
        }
        postChar(char)
        return nil
    }

    private func findInputSourceByID(_ id: String) -> TISInputSource? {
        let props = [kTISPropertyInputSourceID: id as CFString] as CFDictionary
        let list = TISCreateInputSourceList(props, false)?.takeRetainedValue() as? [TISInputSource]
        return list?.first
    }

    private func postChar(_ char: Character) {
        let src = CGEventSource(stateID: .hidSystemState)
        var utf16 = Array(String(char).utf16)
        if let down = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: true) {
            down.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
            down.flags = []
            down.post(tap: .cgAnnotatedSessionEventTap)
        }
        if let up = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: false) {
            up.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
            up.flags = []
            up.post(tap: .cgAnnotatedSessionEventTap)
        }
    }

    private func findASCIILayout() -> TISInputSource? {
        let props = [kTISPropertyInputSourceIsASCIICapable: true,
                     kTISPropertyInputSourceType: kTISTypeKeyboardLayout] as CFDictionary
        let list = TISCreateInputSourceList(props, false)?.takeRetainedValue() as? [TISInputSource]
        return list?.first
    }

    private func sendKey(_ keyCode: CGKeyCode, source: CGEventSource?) {
        let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let up   = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        down?.flags = []
        up?.flags   = []
        down?.post(tap: .cgAnnotatedSessionEventTap)
        up?.post(tap: .cgAnnotatedSessionEventTap)
    }

}

// MARK: - 全域 C Callback

private func globalTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let ptr = refcon else { return Unmanaged.passRetained(event) }
    let manager = Unmanaged<EventTapManager>.fromOpaque(ptr).takeUnretainedValue()

    if type == .tapDisabledByTimeout {
        manager.reenable()
        return Unmanaged.passRetained(event)
    }

    return manager.process(event)
}
