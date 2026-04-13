import AppKit
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let tapManager = EventTapManager()
    private var isEnabled = true

    // MARK: - 啟動

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        requestPermissionAndStart()

        // 監聽輸入法切換（可用來更新 icon 狀態）
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(inputSourceChanged),
            name: .init(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil
        )
    }

    // MARK: - 選單列圖示

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = statusItem.button {
            if let img = NSImage(named: "menubar") {
                img.isTemplate = true
                btn.image = img
            } else if let url = Bundle.module.url(forResource: "menubar", withExtension: "png"),
                      let img = NSImage(contentsOf: url) {
                img.isTemplate = true
                btn.image = img
            } else {
                btn.image = NSImage(systemSymbolName: "keyboard.fill", accessibilityDescription: "1qaz Half")
                btn.image?.isTemplate = true
            }
        }
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let header = NSMenuItem(title: "1qaz Half", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        menu.addItem(.separator())

        let stateItem = NSMenuItem(
            title: isEnabled ? "✓ 運行中" : "✗ 已停用",
            action: nil, keyEquivalent: ""
        )
        stateItem.isEnabled = false
        menu.addItem(stateItem)

        menu.addItem(NSMenuItem(
            title: isEnabled ? "停用" : "啟用",
            action: #selector(toggleTap),
            keyEquivalent: ""
        ))

        menu.addItem(.separator())

        menu.addItem(makeToggle(
            title: "Shift + 字母 → 小寫半形英文",
            state: tapManager.shiftLetterEnabled,
            action: #selector(toggleShiftLetter)
        ))
        menu.addItem(makeToggle(
            title: "Shift + 數字 → 半形符號（!@#…）",
            state: tapManager.shiftNumberEnabled,
            action: #selector(toggleShiftNumber)
        ))
        menu.addItem(makeToggle(
            title: "Shift + 標點 → 半形標點（:{?<…）",
            state: tapManager.shiftPunctEnabled,
            action: #selector(toggleShiftPunct)
        ))
        menu.addItem(makeToggle(
            title: "九宮格 → 半形數字",
            state: tapManager.numpadEnabled,
            action: #selector(toggleNumpad)
        ))

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "輔助使用權限...",
            action: #selector(openAccessibilitySettings),
            keyEquivalent: ""
        ))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "結束 1qaz Half",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        statusItem.menu = menu
    }

    private func makeToggle(title: String, state: Bool, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.state = state ? .on : .off
        return item
    }

    // MARK: - 動作

    @objc private func toggleTap() {
        isEnabled.toggle()
        if isEnabled {
            if !tapManager.start() {
                isEnabled = false
                showPermissionGuide()
            }
        } else {
            tapManager.stop()
        }
        rebuildMenu()
    }

    @objc private func toggleShiftLetter()  { tapManager.shiftLetterEnabled.toggle(); rebuildMenu() }
    @objc private func toggleShiftNumber()  { tapManager.shiftNumberEnabled.toggle(); rebuildMenu() }
    @objc private func toggleShiftPunct()   { tapManager.shiftPunctEnabled.toggle();  rebuildMenu() }
    @objc private func toggleNumpad()       { tapManager.numpadEnabled.toggle();       rebuildMenu() }

    @objc private func openAccessibilitySettings() {
        NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        )
    }

    @objc private func inputSourceChanged() {
        // 未來可在此更新 icon 顯示（例如注音模式時改變顏色）
    }

    // MARK: - 權限

    private func requestPermissionAndStart() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let options = [promptKey: true] as CFDictionary

        if AXIsProcessTrustedWithOptions(options) {
            // 已有權限，直接啟動
            if !tapManager.start() {
                showPermissionGuide()
            }
        } else {
            // 系統已彈出引導視窗，等用戶授權後需重新啟動 App
            showPermissionGuide()
        }
    }

    private func showPermissionGuide() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "需要輔助使用權限"
        alert.informativeText = """
            1qaz Half 需要「輔助使用」權限才能攔截鍵盤事件。

            請前往：
            系統設定 → 隱私權與安全性 → 輔助使用

            開啟 1qaz Half 的權限後，請重新啟動 App。
            """
        alert.addButton(withTitle: "開啟系統設定")
        alert.addButton(withTitle: "稍後")
        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }
}
