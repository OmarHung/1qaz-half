import Carbon
import Foundation

enum InputSourceHelper {

    /// 判斷目前是否為注音輸入法
    static func isBopomofoActive() -> Bool {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return false
        }
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
            return false
        }
        let id = Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
        // 涵蓋內建注音 (com.apple.inputmethod.TCIM.Zhuyin) 及第三方注音輸入法
        return id.contains("Zhuyin") || id.contains("Bopomofo")
    }
}
