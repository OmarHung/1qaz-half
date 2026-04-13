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
            btn.image = loadMenuBarIcon() ?? NSImage(systemSymbolName: "keyboard.fill",
                                                     accessibilityDescription: "1qaz Half")
            btn.image?.isTemplate = true
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
        menu.addItem(makeToggle(
            title: "開機自動啟動",
            state: LoginItemManager.isEnabled,
            action: #selector(toggleLoginItem)
        ))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "診斷資訊...",
            action: #selector(showDiagnostics),
            keyEquivalent: ""
        ))
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

    /// 安全載入選單列圖示，不依賴 Bundle.module（可能 fatalError），任一步驟失敗都不 crash
    private func loadMenuBarIcon() -> NSImage? {
        // 候選 resource bundle 位置（依優先順序）
        let bundleCandidates: [URL] = [
            // .app 打包後的正確位置：Contents/Resources/
            Bundle.main.resourceURL?
                .appendingPathComponent("1qaz-Half_OneQazHalf.bundle") ?? URL(fileURLWithPath: ""),
            // swift run 開發時的位置（executable 同目錄）
            Bundle.main.executableURL?.deletingLastPathComponent()
                .appendingPathComponent("1qaz-Half_OneQazHalf.bundle") ?? URL(fileURLWithPath: ""),
        ]

        for bundleURL in bundleCandidates {
            if let resBundle = Bundle(url: bundleURL),
               let url = resBundle.url(forResource: "menubar", withExtension: "png"),
               let img = NSImage(contentsOf: url) {
                img.isTemplate = true
                return img
            }
        }
        return nil
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

    @objc private func toggleLoginItem() {
        do {
            try LoginItemManager.setEnabled(!LoginItemManager.isEnabled)
        } catch {
            showAlert(title: "無法設定開機啟動",
                      message: "請確認 App 已安裝至 /Applications 資料夾。\n\n錯誤：\(error.localizedDescription)")
        }
        rebuildMenu()
    }

    @objc private func toggleShiftLetter()  { tapManager.shiftLetterEnabled.toggle(); rebuildMenu() }
    @objc private func toggleShiftNumber()  { tapManager.shiftNumberEnabled.toggle(); rebuildMenu() }
    @objc private func toggleShiftPunct()   { tapManager.shiftPunctEnabled.toggle();  rebuildMenu() }
    @objc private func toggleNumpad()       { tapManager.numpadEnabled.toggle();       rebuildMenu() }

    @objc private func showDiagnostics() {
        let trusted   = AXIsProcessTrustedWithOptions(nil)
        let tapActive = tapManager.isRunning
        let inputID   = InputSourceHelper.currentInputSourceID()
        let isBopomofo = InputSourceHelper.isBopomofoActive()

        let info = """
            ── Accessibility ──
            權限已授予：\(trusted ? "✓ 是" : "✗ 否")

            ── Event Tap ──
            Tap 運行中：\(tapActive ? "✓ 是" : "✗ 否")

            ── 輸入法 ──
            目前 ID：\(inputID)
            偵測為注音：\(isBopomofo ? "✓ 是" : "✗ 否（需包含 Zhuyin 或 Bopomofo）")
            """
        print("[診斷]\n\(info)")
        showAlert(title: "1qaz Half 診斷資訊", message: info)
    }

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
        if AXIsProcessTrustedWithOptions(nil) {
            // 已有權限，直接啟動
            _ = tapManager.start()
        } else {
            // 觸發系統授權彈窗
            AXIsProcessTrustedWithOptions(
                [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            )
            // 顯示說明視窗
            showPermissionGuide()
            // 背景輪詢：授權後自動啟動，不需重啟
            startPermissionPolling()
        }
    }

    private func startPermissionPolling() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            if AXIsProcessTrustedWithOptions(nil) {
                timer.invalidate()
                DispatchQueue.main.async {
                    _ = self.tapManager.start()
                    self.rebuildMenu()
                    print("[1qaz Half] 已取得輔助使用權限，Event tap 啟動中")
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
        NSApp.setActivationPolicy(.accessory)
    }

    /// 顯示提示視窗（Accessory app 需要先切換成 .regular 才能正確彈出視窗）
    private func showPermissionGuide() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "需要輔助使用權限"
        alert.informativeText = """
            1qaz Half 需要「輔助使用」權限才能攔截鍵盤事件。

            請前往：
            系統設定 → 隱私權與安全性 → 輔助使用

            開啟 1qaz Half 的權限後即自動生效，無需重啟。
            """
        alert.addButton(withTitle: "開啟系統設定")
        alert.addButton(withTitle: "稍後")

        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }

        // 提示關閉後切回 accessory，隱藏 Dock 圖示
        NSApp.setActivationPolicy(.accessory)
    }
}
