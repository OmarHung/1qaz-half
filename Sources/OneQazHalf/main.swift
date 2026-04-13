import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // 等同於 LSUIElement = YES，隱藏 Dock 圖示
let delegate = AppDelegate()
app.delegate = delegate
app.run()
