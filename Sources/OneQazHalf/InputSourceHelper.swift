import Carbon
import Foundation

enum InputSourceHelper {

    /// 取得目前輸入法 ID
    static func currentInputSourceID() -> String {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID)
        else { return "(unknown)" }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }

    /// 判斷目前是否為注音輸入法
    static func isBopomofoActive() -> Bool {
        let id = currentInputSourceID()
        return id.contains("Zhuyin") || id.contains("Bopomofo")
    }
}
