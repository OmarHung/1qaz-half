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
| `Shift` + 字母 | 小寫半形英文（`a`~`z`） |
| `Shift` + 數字鍵 | 半形符號（`!` `@` `#` `$` `%` `^` `&` `*` `(` `)`） |
| `Shift` + 標點鍵 | 半形標點（`:` `"` `?` `<` `>` `{` `}` `\|` `~`） |
| 九宮格數字鍵 | 半形數字與運算符（`0`~`9`、`+` `-` `*` `/` `.` `=`） |

**選字狀態下觸發以上按鍵**，會自動清除注音組字後輸出目標字元。

---

## 安裝

### 下載安裝（推薦）

1. 前往 [Releases](https://github.com/OmarHung/1qaz-half/releases/latest) 下載 `1qaz.Half.zip`
2. 解壓縮後將 `1qaz Half.app` 移至 `/Applications`
3. 開啟 app
4. 依提示前往 **系統設定 → 隱私權與安全性 → 輔助使用**，開啟 1qaz Half 的權限
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
- **選字狀態清除方式**
  - `Enter 提交選字`（預設）：無延遲，適合大多數情境
  - `切換輸入法取消組字`：延遲約 100ms，相容性較佳
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

## 升級方式

每次重新安裝需重新授權 Accessibility 權限（macOS 以路徑識別 app，重新安裝後視為新 app）：

```bash
rm -rf /Applications/1qaz\ Half.app
cp -R "1qaz Half.app" /Applications/
```

接著到 **系統設定 → 隱私權與安全性 → 輔助使用**，移除舊的 1qaz Half 記錄並重新授權。

---

## License

MIT
