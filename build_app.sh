#!/bin/bash
set -e

APP_NAME="1qaz Half"
BUNDLE_ID="com.omarhung.1qaz-half"
VERSION="1.0.0"
EXECUTABLE="OneQazHalf"

echo "▸ Building release..."
swift build -c release

echo "▸ Creating app bundle..."
APP_DIR="$APP_NAME.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# 複製執行檔
cp ".build/release/$EXECUTABLE" "$APP_DIR/Contents/MacOS/"

# 複製 SPM 資源 bundle 到 Contents/Resources（符合 bundle 規範，codesign 才不會拒絕）
RESOURCE_BUNDLE=$(find -L .build/release -name "*.bundle" -maxdepth 1 | head -1)
if [ -n "$RESOURCE_BUNDLE" ]; then
    cp -R "$RESOURCE_BUNDLE" "$APP_DIR/Contents/Resources/"
    echo "  ✓ Resource bundle: $(basename $RESOURCE_BUNDLE)"
else
    echo "  ⚠ Resource bundle not found"
fi

# 複製 AppIcon 到 Contents/Resources（Finder 用）
cp "Sources/OneQazHalf/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/"

# 建立 Info.plist
cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>1qaz Half</string>
    <key>CFBundleDisplayName</key>
    <string>1qaz Half</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleExecutable</key>
    <string>${EXECUTABLE}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>1qaz Half 需要輔助使用權限以攔截鍵盤事件，實現注音模式下的半形輸出。</string>
</dict>
</plist>
EOF

# Ad-hoc 簽名（讓 macOS 能穩定識別 app identity，Accessibility 授權才不會失效）
echo "▸ Signing..."
codesign --force --deep --sign - "$APP_DIR"
echo "  ✓ Ad-hoc signed"

echo ""
echo "✓ $APP_DIR 已建立並簽名"
echo ""
echo "▸ 安裝到 Applications 並授權（第一次需要做）："
echo ""
echo "  1. 複製到 Applications："
echo "       cp -R \"$APP_DIR\" /Applications/"
echo ""
echo "  2. 開啟 app（會自動請求 Accessibility 授權）："
echo "       open /Applications/1qaz\\ Half.app"
echo ""
echo "  3. 系統設定 → 隱私權與安全性 → 輔助使用 → 開啟 1qaz Half"
echo ""
echo "  ⚠ 每次重新打包後需移除舊版再重新安裝並重新授權："
echo "       rm -rf /Applications/1qaz\\ Half.app"
echo "       cp -R \"$APP_DIR\" /Applications/"
