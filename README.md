# 1qaz Half

**注音輸入法半形輸出助手** — 讓注音模式下中英混打更順暢。

> 1qaz 取自注音鍵盤第一排：ㄅ ㄆ ㄇ ㄈ 對應的按鍵位置。

![macOS](https://img.shields.io/badge/macOS-12%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 功能

在注音輸入法模式下，以下按鍵直接輸出半形字元，無需切換輸入法：

| 按鍵組合 | 輸出 |
|---------|------|
| `Shift` + 字母 | 半形英文（大寫或小寫，可設定） |
| `Shift` + 數字鍵 | 半形符號（`!` `@` `#` `$` `%` `^` `&` `*` `(` `)`） |
| `Shift` + 標點鍵 | 半形標點（`:` `"` `?` `<` `>` `{` `}` `\|` `~`） |
| 九宮格數字鍵 | 半形數字與運算符（`0`~`9`、`+` `-` `*` `/` `.` `=`） |

**選字狀態下觸發以上按鍵**，會自動清除注音組字後輸出目標字元。

---

## 安裝

### 下載安裝（推薦）

1. 前往 [Releases](https://github.com/OmarHung/1qaz-half/releases/latest) 下載 `1qaz.Half.zip`
2. 解壓縮後將 `1qaz Half.app` 移至 `/Applications`
3. **第一次開啟**：直接雙擊會出現「無法驗證開發者」的警告，請依以下步驟處理：
   1. 前往 **系統設定 → 隱私權與安全性**
   2. 往下捲動，找到「已阻擋 1qaz Half.app，以保護你的Mac。」
   3. 點擊旁邊的 **「強制打開」**
   4. 在彈出的確認視窗再次點擊 **「強制打開」**
4. App 開啟後，依提示前往 **系統設定 → 隱私權與安全性 → 輔助使用**，開啟 1qaz Half 的權限
5. 授權後自動生效，無需重啟

### 從原始碼建置

```bash
git clone https://github.com/OmarHung/1qaz-half.git
cd 1qaz-half
bash build_app.sh
cp -R "1qaz Half.app" /Applications/
```

---

## 選單說明

點選選單列圖示可調整以下設定：

- **功能開關**：各功能可單獨開啟或關閉
  - `Shift` + 字母功能下方可選擇輸出**小寫（abc）**或**大寫（ABC）**，未啟用時選項自動變灰

- **選字狀態清除方式**：在注音組字或選字狀態下觸發功能鍵時，需先清除 IME buffer 才能輸出目標字元。分為**全域預設**與**個別 App 設定**兩區塊，可針對不同程式使用不同方式：

  | 模式 | 實作方式 | 優點 | 缺點 |
  |------|---------|------|------|
  | `End 鍵退出選字`（預設） | 注入 End 鍵讓 IME 退出選字狀態，再輸出目標字元 | 無延遲、即時 | 實際行為依 IME 版本與 app 而異 |
  | `Enter 提交選字` | 注入 Enter 鍵讓 IME 提交目前選字，再輸出目標字元 | 無延遲、即時 | ⚠️ 若狀態誤判，Enter 可能直接送至 app，在 LINE、Telegram 等造成文字提早送出 |
  | `切換輸入法取消組字` | 暫時切換至 ABC 輸入法（自動取消組字）→ 輸出字元 → 切回注音 | 完全不送任何鍵盤事件給 app | 約 100ms 延遲，輸入法圖示會短暫閃動 |
  | `關閉（不處理）` | 不清除 IME 狀態，直接輸出目標字元 | 無任何副作用 | 選字狀態下輸出字元可能被 IME 吃掉 |

  個別 App 設定選「**使用全域預設**」可移除覆蓋，回到全域設定。

  > **原理補充**：macOS 沒有提供公開 API 讓外部程式查詢 IME 目前是否在選字狀態，因此採用啟發式追蹤（heuristic）——記錄是否有注音字母鍵被輸入過，作為判斷依據。

- **開機自動啟動**
- **檢查更新**

---

## 系統需求

- macOS 12 Monterey 以上
- 注音輸入法（內建 TCIM 注音或相容輸入法）
- 輔助使用（Accessibility）權限

---

## 為什麼需要輔助使用權限？

1qaz Half 透過 macOS 的 `CGEvent Tap` 機制，在注音輸入法之前攔截鍵盤事件，攔截到目標按鍵時將其轉換為半形字元輸出。此機制需要輔助使用權限才能運作。

App 不會收集任何個人資料，所有處理均在本機完成。

---

## 為什麼每次安裝都要重新到安全性設定授權？

macOS 的 Accessibility 授權機制是以 **code signature（程式碼簽名）** 來識別 app 身份。

1qaz Half 目前使用 **ad-hoc 簽名**（本機自簽，不需 Apple Developer 帳號），其 identity 是根據 binary 內容計算出的 hash。只要重新編譯或更新版本，binary 內容改變，hash 就跟著變，macOS 便視為全新的 app，之前的授權記錄自動失效。

如果使用 Apple Developer Program（$99 USD/年）的 Developer ID 憑證簽名，則 identity 固定，升級後不需要重新授權。目前 1qaz Half 為個人開發的免費工具，暫不申請。

---

## 升級方式

每次安裝新版本需重新授權 Accessibility 權限：

```bash
rm -rf /Applications/1qaz\ Half.app
cp -R "1qaz Half.app" /Applications/
```

接著到 **系統設定 → 隱私權與安全性 → 輔助使用**，移除舊的 1qaz Half 記錄並重新授權。

---

## License

MIT
